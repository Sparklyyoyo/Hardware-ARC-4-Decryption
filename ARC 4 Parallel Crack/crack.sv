/* 
--- File:    crack.sv
--- Module:  crack
--- Brief:   Brute-force driver that iterates ARC4 keys and validates plaintext bytes are printable ASCII.

--- Description:
---   Orchestrates key trials for an ARC4 block (arc4) by stepping a 24-bit key, running PRGA/KSA via
---   the arc4 submodule, and checking produced plaintext bytes. If any byte is non-printable ASCII
---   (outside 0x20–0x7E) while pt_wren is asserted, it advances to the next key. When all bytes in the
---   message pass, it raises key_valid and holds the discovered key.

--- Interfaces:
---   clk, rst_n             : Clock and async active-low reset.
---   en, rdy                : Start/ready handshake.
---   key, key_valid         : Current trial key and valid flag when found.
---   ct_addr, ct_rddata     : Ciphertext read port to arc4 path.
---   key_inital             : 2-bit initial key seed (LSBs) to start the search.
---   pt_addr_in             : Address used to read out final plaintext when key is found.
---   pt_rddata              : Plaintext data read from internal PT memory (length-prefixed).
---   Submodules             : pt_mem (PT buffer), arc4 (RC4 pipeline).

--- Author: Joey Negm
*/

`timescale 1ps / 1ps

module crack(
    input  logic        clk, 
    input  logic        rst_n,
    input  logic        en, 
    output logic        rdy,
    output logic [23:0] key, 
    output logic        key_valid,
    output logic [7:0]  ct_addr, 
    input  logic [7:0]  ct_rddata, 
    input  logic [1:0]  key_inital, 
    input  logic [7:0]  pt_addr_in, 
    output logic [7:0]  pt_rddata);

    // --- Internal registers ---
    //Readable from 32 - 126 inclusive ('h20 - 'h7E)

    enum {INITALIZE, READ_message_length, New_Key, Crack_Key, No_Key_Found, Key_Found, ERROR} state;
    
    logic [7:0]  pt_addr_a4;
    logic [7:0]  pt_addr;
    logic [7:0]  pt_wrdata;
    logic [23:0] key_math;
    logic [7:0]  message_length;
    logic        pt_wren;
    logic        pt_wren_a4;
    logic        newkey_flag;
    logic [7:0]  ct_addr_a4;
    logic        en_a4;
    logic        rdy_a4;
    logic        flag_pt_wren;
    logic        rst_a4;

    // --- Instantiate submodules ---
    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem ptc(.address(pt_addr), .clock(clk), .data(pt_wrdata), .wren(pt_wren), .q(pt_rddata));
    arc4 a4(.clk(clk), .rst_n(rst_n), .en(en_a4), .rdy(rdy_a4), .key(key), .ct_addr(ct_addr_a4), .ct_rddata(ct_rddata),
     .pt_addr(pt_addr_a4), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren_a4));

    // --- Sequential: state & registers updates ---
    always_ff @(posedge clk) begin
        if(~rst_n) begin
            state          <= INITALIZE;
            newkey_flag    <= 1;
            key_math       <= key_inital;
            message_length <= 0;
        end
        else begin
            case(state)
                INITALIZE: begin
                    if(en) begin
                        state <= READ_message_length;
                    end
                    else begin
                        state <= INITALIZE;
                    end
                end

                READ_message_length: state <= New_Key;

                New_Key: begin
                    if(rdy_a4)
                        state <= Crack_Key;
                    else 
                        state <= New_Key;
                end

                Crack_Key: begin
                    if(((pt_wrdata < 8'h20) || (pt_wrdata > 8'h7E)) && pt_wren) begin
                        state <= New_Key;
                    end
                    else if(pt_addr < message_length) begin
                        state <= Crack_Key;
                    end
                    else
                        state <= Key_Found;
                end

                No_Key_Found: state <= No_Key_Found;
                Key_Found:    state <= Key_Found;
                default:      state <= ERROR;
            endcase

            // --- State-dependent register updates ---
            case (state)
                INITALIZE: begin
                    newkey_flag     <= 1;
                    key_math        <= key_inital;
                    message_length  <= 0;
                end

                READ_message_length: begin
                    // No state updates
                end

                New_Key: begin
                    if(message_length === 8'd0) begin
                        message_length <= ct_rddata;
                    end

                    if(newkey_flag) begin
                        key_math <= key_math + 2;
                    end

                    flag_pt_wren <= 1'b0;
                    newkey_flag  <= 1'b0;
                end

                Crack_Key: begin
                    newkey_flag <= 1'b1;

                    if(pt_wren) begin
                        flag_pt_wren <= 1'b1;
                    end
                end

                No_Key_Found: begin
                    // No state updates
                end

                Key_Found: begin
                    // No state updates
                end

                default:state <= ERROR; 
            endcase
        end
    end

    // --- Combinational: outputs ---
    always_comb begin
        case (state)
            INITALIZE: begin
                key_valid = 1'b0;
                rdy       = 1'b1;
                key       = key_math;
                ct_addr   = 8'd0;
                en_a4     = 1'b0;
                rst_a4    = 1'b0;
                pt_addr   = pt_addr_a4;
                pt_wren   = pt_wren_a4;
            end

            READ_message_length: begin
                key_valid = 1'b0;
                rdy       = 1'b0;
                key       = key_math;
                ct_addr   = 8'd0;
                en_a4     = 1'b0;
                rst_a4    = 1'b1;
                pt_addr   = pt_addr_a4;
                pt_wren   = pt_wren_a4;
            end

            New_Key: begin
                key_valid = 1'b0;
                rdy       = 1'b0;
                key       = key_math;
                ct_addr   = ct_addr_a4;
                en_a4     = 1'b0;
                rst_a4    = 1'b0;
                pt_addr   = pt_addr_a4;
                pt_wren   = pt_wren_a4;
            end

            Crack_Key: begin
                key_valid = 1'b0;
                rdy       = 1'b0;
                key       = key_math;
                ct_addr   = ct_addr_a4;
                en_a4     = 1'b1;
                rst_a4    = 1'b1;
                pt_addr   = pt_addr_a4;
                pt_wren   = pt_wren_a4;
            end

            No_Key_Found: begin
                key_valid = 1'b0;
                rdy       = 1'b1;
                key       = key_math;
                ct_addr   = ct_addr_a4;
                en_a4     = 1'b0;
                rst_a4    = 1'b1;
                pt_addr   = pt_addr_a4;
                pt_wren   = pt_wren_a4;
            end

            Key_Found: begin
                key_valid = 1'b1;
                rdy       = 1'b1;
                key       = key_math;
                ct_addr   = ct_addr_a4;
                en_a4     = 1'b0;
                rst_a4    = 1'b1;
                pt_addr   = pt_addr_in;
                pt_wren   = 1'b0;
            end

            default: begin
                key_valid = 'x;
                rdy       = 'x;
                key       = 'x;
                ct_addr   = ct_addr_a4;
                en_a4     = 'x;
                rst_a4    = 'x;
                pt_addr   = pt_addr_a4;
                pt_wren   = pt_wren_a4;
            end
        endcase
    end
endmodule: crack
