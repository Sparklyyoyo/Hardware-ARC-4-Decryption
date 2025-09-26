/* 
--- File:    prga.sv
--- Module:  prga
--- Brief:   ARC4 Pseudo-Random Generation Algorithm (PRGA) FSM with Avalon-style S/CT/PT interfaces.

--- Description:
---   Iteratively generates keystream bytes from S, XORs with ciphertext to produce plaintext, and
---   writes results to PT memory. Uses a small internal pad[] buffer and exposes separate S/CT/PT ports.
---   State flow: INITALIZE → READ_message_length → READ_i → READ_j → WRITE_i → WRITE_j → READ_si_sj
---               → (READ_i | WRITE_pt) … with READ_ct between PT writes as needed.

--- Interfaces:
---   clk, rst_n           : Clock and active-low reset.
---   en, rdy              : Start and ready handshake.
---   key[23:0]            : 24-bit key (latched/used in KSA phase upstream).
---   S-port               : s_addr, s_rddata, s_wrdata, s_wren (permutes S).
---   Ciphertext port      : ct_addr, ct_rddata (reads ciphertext).
---   Plaintext port       : pt_addr, pt_rddata, pt_wrdata, pt_wren (writes plaintext).

--- Author: Joey Negm
*/

`timescale 1ps / 1ps

module prga(
    input  logic        clk, 
    input  logic        rst_n,
    input  logic        en, 
    output logic        rdy,
    input  logic [23:0] key,

    // --- S-box memory interface ---
    output logic [7:0]  s_addr, 
    input  logic [7:0]  s_rddata, 
    output logic [7:0]  s_wrdata, 
    output logic        s_wren,

    // --- Ciphertext memory interface ---
    output logic [7:0]  ct_addr, 
    input  logic [7:0]  ct_rddata,

    // --- Plaintext memory interface ---
    output logic [7:0]  pt_addr, 
    input  logic [7:0]  pt_rddata, 
    output logic [7:0]  pt_wrdata, 
    output logic        pt_wren
    );

    // --- Internals ---
    logic [7:0] pad [0:255];

    logic [7:0] i;
    logic [7:0] s_i;

    logic [7:0] j;
    logic [7:0] s_j;

    logic [7:0] k;
    logic [7:0] ct_k;
    logic [7:0] temp_si;
    logic [7:0] temp_sj;
    logic [7:0] si_sj;
    logic [7:0] message_length;
    logic       flag;
    logic       READ_i_NEXT;
    logic       WRITE_pt_NEXT;

    enum {INITALIZE, READ_message_length, READ_i, READ_j, READ_si_sj, WRITE_i, WRITE_j, WRITE_pt, READ_ct, ERROR} state;

    // --- Sequential: state & registers updates ---
    always_ff @(posedge clk) begin
        if(~rst_n) begin
            state <= INITALIZE;
            i              <= 8'd0;
            j              <= 8'd0;
            s_i            <= 8'd0;
            s_j            <= 8'd0;
            k              <= 8'd1;
            si_sj          <= 8'd0;
            flag           <= 1'b0;
            ct_k           <= 8'd0;
            message_length <= 8'd0;
            READ_i_NEXT    <= 1'b0;
            WRITE_pt_NEXT  <= 1'b0;
        end
        else begin
            case (state)
                INITALIZE: begin 
                    if(en)
                        state <= READ_message_length;
                    else
                        state <= INITALIZE;
                end

                READ_message_length: state <= READ_i;
                READ_i:              state <= READ_j;
                READ_j:              state <= WRITE_i;
                WRITE_i:             state <= WRITE_j;
                WRITE_j:             state <= READ_si_sj;

                READ_si_sj: begin
                    if(k < message_length) begin
                        state      <= READ_i;
                        READ_i_NEXT = 1'b1;
                    end
                    else begin
                        state        <= WRITE_pt;
                        WRITE_pt_NEXT = 1'b1;
                    end
                end

                WRITE_pt: begin                   
                    if(k < message_length)
                        state <= READ_ct;
                    else
                        state <= INITALIZE;
                end

                READ_ct: state <= WRITE_pt;
                default: state <= ERROR;
            endcase

            case (state)
                INITALIZE: begin
                    i              <= 8'd0;
                    j              <= 8'd0;
                    k              <= 8'd1;
                    s_i            <= 8'd0;
                    s_j            <= 8'd0;
                    flag           <= 1'b0;
                    si_sj          <= 8'd0;
                    ct_k           <= 8'd0;
                    message_length <= 8'd0;
                    READ_i_NEXT     = 1'b0;
                    WRITE_pt_NEXT   = 1'b0;
                end

                READ_message_length: begin
                    // No state updates needed
                end
                
                READ_i: begin
                    if(READ_i_NEXT === 1'b1) begin
                        pad[k - 1] <= s_rddata;
                        si_sj      <= s_rddata;
                    end
                    READ_i_NEXT     = 1'b0;
                    message_length <= ct_rddata;
                    i              <= (i + 1) % 256;
                end

                READ_j: begin
                    s_i <= s_rddata;
                    j <= (j + temp_si) % 256;
                end

                WRITE_i: begin
                    s_j <= s_rddata;
                end

                WRITE_j: begin
                    // No state updates needed
                end

                READ_si_sj: begin 
                    if(k === message_length)
                        k <= 8'd1;
                    else
                        k <= k + 1;
                end

                WRITE_pt: begin
                    if(WRITE_pt_NEXT === 1'b1)
                        pad[message_length] <= s_rddata;

                    WRITE_pt_NEXT = 1'b0;

                    if(flag === 1'b0)
                        flag = 1'b1;
                    else begin
                        ct_k <= ct_rddata;
                        k    <= k + 1'b1;
                    end
                end

                READ_ct: begin
                    // No state updates needed
                end

                default: begin
                    i              <= i;
                    j              <= j;
                    s_i            <= s_i;
                    s_j            <= s_j;
                    k              <= k;
                    si_sj          <= si_sj;
                    flag           <= flag;
                    ct_k           <= ct_k;
                    message_length <= message_length;
                end
            endcase
        end
    end

    //--- Combinational: outputs ---

    always_comb begin
        case (state)
            INITALIZE: begin
                rdy       = 1'b1;

                s_addr    = 8'd0;
                s_wrdata  = 8'd0;
                s_wren    = 1'b0;

                ct_addr   = 8'd0;

                pt_addr   = 8'd0;
                pt_wrdata = 8'd0;
                pt_wren   = 1'b0;

                temp_si   = 8'd0;
                temp_sj   = 8'd0;
            end

            READ_message_length: begin
                rdy       = 1'b0;

                s_addr    = 8'd0;
                s_wrdata  = 8'd0;
                s_wren    = 1'b0;

                ct_addr   = 8'd0;

                pt_addr   = 8'd0;
                pt_wrdata = 8'd0;
                pt_wren   = 1'b0;

                temp_si   = 8'd0;
                temp_sj   = 8'd0;
            end

            READ_i: begin
                rdy       = 1'b0;

                s_addr    = (i + 1) % 256;
                s_wrdata  = 8'd0;
                s_wren    = 1'b0;

                ct_addr   = 8'd0;

                pt_addr   = 8'd0;
                pt_wrdata = 8'd0;
                pt_wren   = 1'b0;

                temp_si   = 8'd0;
                temp_sj   = 8'd0;
            end
    
            READ_j: begin
                rdy       = 1'b0;
                temp_si   = s_rddata;
                
                s_addr    = (j + temp_si) % 256;
                s_wrdata  = 8'd0;
                s_wren    = 1'b0;

                ct_addr   = 8'd0;

                pt_addr   = 8'd0;
                pt_wrdata = 8'd0;
                pt_wren   = 1'b0;

                temp_sj   = 8'd0;
            end

            READ_si_sj: begin
                rdy       = 1'b0;
                s_addr    = (s_i + s_j) % 256;
                s_wrdata  = 8'd0;
                s_wren    = 1'b0;

                ct_addr   = 8'd0;

                pt_addr   = 8'd0;
                pt_wrdata = 8'd0;
                pt_wren   = 1'b0;

                temp_sj   = 8'd0;
                temp_si   = 8'd0;
            end

            WRITE_i: begin
                temp_sj   = s_rddata;
                rdy       = 1'b0;

                s_addr    = i;
                s_wrdata  = temp_sj;
                s_wren    = 1'b1;

                ct_addr   = 8'd0;

                pt_addr   = 8'd0;
                pt_wrdata = 8'd0;
                pt_wren   = 1'b0;

                temp_si   = 8'd0;
            end
    
            WRITE_j: begin
                rdy       = 1'b0;

                s_addr    = j;
                s_wrdata  = s_i;
                s_wren    = 1'b1;

                ct_addr   = 8'd0;

                pt_addr   = 8'd0;
                pt_wrdata = 8'd0;
                pt_wren   = 1'b0;

                temp_si   = 8'd0;
                temp_sj   = 8'd0;
            end
    
            WRITE_pt: begin
                rdy       = 1'b0;

                s_addr    = 8'd0;
                s_wrdata  = 8'd0;
                s_wren    = 1'b0;

                ct_addr   = 8'd0;

                if(flag === 1'b0) begin
                    pt_addr   = 8'd0;
                    pt_wrdata = message_length;
                    pt_wren   = 1'b1;
                end
                else begin
                    pt_addr = k;
                    pt_wrdata = pad[k] ^ ct_rddata;
                    pt_wren = 1;
                end

                temp_si = 8'd0;
                temp_sj = 8'd0;
            end
    
            READ_ct: begin
                rdy       = 1'b0;
                s_addr    = 8'd0;
                s_wrdata  = 8'd0;
                s_wren    = 1'b0;

                ct_addr   = k;

                pt_addr   = 8'd0;
                pt_wrdata = 8'd0;
                pt_wren   = 1'b0;

                temp_si   = 8'd0;
                temp_sj   = 8'd0;
            end
    
            default: begin
                rdy = 'x;

                s_addr = 'x;
                s_wrdata = 'x;
                s_wren = 'x;

                ct_addr = 'x;

                pt_addr = 'x;
                pt_wrdata = 'x;
                pt_wren = 'x;

                temp_si = 'x;
                temp_sj = 'x;
            end
        endcase
    end
endmodule: prga
