/* 
--- File:    ksa.sv
--- Module:  ksa
--- Brief:   Implements the ARC4 Key-Scheduling Algorithm (KSA) state machine.

--- Description:
---   Iteratively permutes the S-box using the key provided.
---   Reads S[i], computes j = (j + S[i] + key[i mod 3]) mod 256,
---   then swaps S[i] and S[j] to spread key entropy across the state.

--- Interfaces:
---   clk, rst_n : System clock and active-low reset.
---   en, rdy    : Start signal (en) and ready flag (rdy).
---   key        : 24-bit key used for scheduling.
---   addr       : Address output (used to read/write S-box).
---   rddata     : Data read from S-box.
---   wrdata     : Data to write back to S-box.
---   wren       : Write enable signal.

--- Author: Joey Negm
*/

`timescale 1ps / 1ps

module ksa(
    input  logic        clk, 
    input  logic        rst_n,
    input  logic        en, 
    output logic        rdy,
    input  logic [23:0] key,
    output logic [7:0] addr, 
    input  logic [7:0] rddata, 
    output logic [7:0] wrdata, 
    output logic        wren
    );

    // --- Internal registers ---
    logic [7:0] i;
    logic [7:0] s_i;
    logic [7:0] temp_si;
    logic [7:0] j;
    logic [7:0] s_j;
    logic [7:0] counter;

    enum {INITALIZE, READ_i, READ_j, WAIT_i, WAIT_j, WRITE_i, WRITE_j, ERROR} state;

    // --- Sequential: state & registers updates ---
    always_ff @(posedge clk) begin
        if(~rst_n) begin
            state   <= INITALIZE;
            counter <= 0;
            i       <= 0;
            j       <= 0;
            s_i     <= 0;
            s_j     <= 0;
        end
        else begin
            case (state)
                INITALIZE: begin 
                    if(en)
                        state <= READ_i;
                    else
                        state <= INITALIZE;
                end

                READ_i: state  <= READ_j;
                READ_j: state  <= WRITE_i;
                WRITE_i: state <= WRITE_j;

                WRITE_j: begin
                    if(counter < 8'd255)
                        state <= READ_i;
                    else
                        state <= INITALIZE;
                end

                default: state <= ERROR;
            endcase

            case (state)
                INITALIZE: begin
                    counter <= 0;
                    i       <= 0;
                    j       <= 0;
                    s_i     <= 0;
                    s_j     <= 0;
                end
                
                READ_j: begin 
                    i       <= i;
                    s_i     <= rddata;

                    case (i % 3)
                        0: j <= (j + temp_si + key[23:16]) % 256;
                        1: j <= (j + temp_si + key[15:8]) % 256;
                        2: j <= (j + temp_si + key[7:0]) % 256;
                    endcase

                    s_j <= s_j;
                end

                WRITE_i: begin
                    i       <= i;
                    j       <= j;
                    s_i     <= s_i;
                    s_j     <= rddata;
                end

                WRITE_j: begin
                    j       <= j;
                    s_i     <= s_i;
                    i       <= i + 1;
                    counter <= counter + 1;
                    s_j     <= s_j;
                end

                default: begin
                    i       <= i;
                    j       <= j;
                    s_i     <= s_i;
                    s_j     <= s_j;
                end
            endcase
        end
    end

    // --- Combinational: outputs ---
    always_comb begin
        case (state)
            INITALIZE: begin
                rdy     = 1'b1;
                addr    = 1'b0;
                wrdata  = 1'b0;
                wren    = 1'b0;
                temp_si = 'x;
            end

            READ_i: begin
                rdy     = 1'b0;
                addr    = i;
                wrdata  = 8'd0;
                wren    = 1'b0;
                temp_si = 'x;
            end

            READ_j: begin
                temp_si = rddata;
                case (i % 3)
                    0: addr = (j + temp_si + key[23:16]) % 256; // uses the leftmost 4 bits
                    1: addr = (j + temp_si + key[15:8]) % 256;  // uses the middle 4 bits
                    2: addr = (j + temp_si + key[7:0]) % 256;  // uses the rightmost 4 bits
                    default: addr = 'x;
                endcase
                rdy     = 1'b0;
                wrdata  = 8'd0;
                wren    = 1'b0;
            end

            WRITE_i: begin
                rdy     = 1'b0;
                addr    = i;
                wrdata  = rddata;
                wren    = 1'b1;
                temp_si = 'x;
            end

            WRITE_j: begin
                rdy     = 1'b0;
                addr    = j;
                wrdata  = s_i;
                wren    = 1'b1;
                temp_si = 'x;
            end

            default: begin
                rdy     = 1'b0;
                addr    = 1'b0;
                wrdata  = 8'd0;
                wren    = 1'b0;
                temp_si = 'x;
            end
        endcase   
    end
endmodule: ksa
