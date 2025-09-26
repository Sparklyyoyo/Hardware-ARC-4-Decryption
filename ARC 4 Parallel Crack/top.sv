/* 
--- File:    top.sv
--- Module:  top
--- Brief:   Top-level wrapper that runs doublecrack and displays the discovered 24-bit key on HEX0–HEX5.

--- Description:
---   Instantiates a ciphertext memory (ct_mem) and the doublecrack engine. Once cracking completes,
---   shows the 24-bit key in hex across six 7-segment displays (HEX0 least-significant nibble).
---   HEX displays remain off while cracking and show dashes if no valid key.

--- Interfaces:
---   Inputs : CLOCK_50, KEY[3:0] (KEY[3] = async active-low reset), SW[9:0]
---   Outputs: HEX0..HEX5 (7-seg), LEDR[9:0]

--- Author: Joey Negm
*/

`timescale 1ps / 1ps

`define ZERO  7'b1000000
`define ONE   7'b1111001
`define TWO   7'b0100100
`define THREE 7'b0110000
`define FOUR  7'b0011001
`define FIVE  7'b0010010
`define SIX   7'b0000010
`define SEVEN 7'b1111000
`define EIGHT 7'b0000000
`define NINE  7'b0010000

`define A     7'b0001000
`define B     7'b0000011
`define C     7'b1000110
`define D     7'b0100001
`define E     7'b0000110
`define F     7'b0001110

`define DASH  7'b0111111
`define OFF   7'b1111111


module top(
    input  logic       CLOCK_50, 
    input  logic [3:0] KEY, 
    input  logic [9:0] SW,
    output logic [6:0] HEX0, 
    output logic [6:0] HEX1, 
    output logic [6:0] HEX2,
    output logic [6:0] HEX3, 
    output logic [6:0] HEX4, 
    output logic [6:0] HEX5,
    output logic [9:0] LEDR
    );

    // --- Ciphertext memory interface ---
    logic [7:0]  ct_addr;
    logic [7:0]  ct_rddata;
    logic        ct_wren;
    logic [7:0]  ct_wrdata;

    // --- Crack engine interface ---
    logic        rdy;
    logic [23:0] key;
    logic        key_valid;
    logic        crack_flag;

    // --- State machine ---
    enum {CRACK, DONE, ERROR} state;

    // --- Default assignments ---
    assign LEDR = 10'b0000000000;
    assign ct_wren   = 0;
    assign ct_wrdata = 0;

    // --- Module instantiations ---
    ct_mem ct(.address(ct_addr), .clock(CLOCK_50), .data(ct_wrdata), .wren(ct_wren), .q(ct_rddata));
    doublecrack c(.clk(CLOCK_50), .rst_n(KEY[3]), .en(KEY[3]), .rdy(rdy), .key(key), .key_valid(key_valid), .ct_addr(ct_addr), .ct_rddata(ct_rddata));

    // --- Sequential: state & registers updates ---
    always_ff@(posedge CLOCK_50) begin
        if(~KEY[3]) begin
            state      <= CRACK;
            crack_flag <= 0;
        end
        else begin
            case(state)
                CRACK: begin
                    if(crack_flag && rdy)
                        state <= DONE;
                    else 
                        state <= CRACK;
                end

                DONE:    state <= DONE;
                default: state <= ERROR;
            endcase

            case (state)
                CRACK: begin
                    if(~rdy) begin
                        crack_flag <= 1;
                    end
                end

                DONE: begin
                    // Hold values
                end

                default: begin
                    // Hold values
                end
            endcase
        end
    end

    // --- 7-segment display decoder ---
    always_comb begin
        HEX0 = `OFF;
        HEX1 = `OFF;
        HEX2 = `OFF;
        HEX3 = `OFF;
        HEX4 = `OFF;
        HEX5 = `OFF;
        case(state)
            CRACK: begin
                // Displays remain off while cracking
            end
            
            DONE: begin 
                if(key_valid) begin
                    case(key[3:0])
                        4'h0:HEX0     = `ZERO;
                        4'h1:HEX0     = `ONE;
                        4'h2:HEX0     = `TWO;
                        4'h3:HEX0     = `THREE;
                        4'h4:HEX0     = `FOUR;
                        4'h5:HEX0     = `FIVE;
                        4'h6:HEX0     = `SIX;
                        4'h7:HEX0     = `SEVEN;
                        4'h8:HEX0     = `EIGHT;
                        4'h9:HEX0     = `NINE;
                        4'hA:HEX0     = `A;
                        4'hB:HEX0     = `B;
                        4'hC:HEX0     = `C;
                        4'hD:HEX0     = `D;
                        4'hE:HEX0     = `E;
                        4'hF:HEX0     = `F;
                        default: HEX0 = `DASH;
                    endcase

                    case(key[7:4])
                        4'h0:HEX1     = `ZERO;
                        4'h1:HEX1     = `ONE;
                        4'h2:HEX1     = `TWO;
                        4'h3:HEX1     = `THREE;
                        4'h4:HEX1     = `FOUR;
                        4'h5:HEX1     = `FIVE;
                        4'h6:HEX1     = `SIX;
                        4'h7:HEX1     = `SEVEN;
                        4'h8:HEX1     = `EIGHT;
                        4'h9:HEX1     = `NINE;
                        4'hA:HEX1     = `A;
                        4'hB:HEX1     = `B;
                        4'hC:HEX1     = `C;
                        4'hD:HEX1     = `D;
                        4'hE:HEX1     = `E;
                        4'hF:HEX1     = `F;
                        default: HEX1 = `DASH;
                    endcase

                    case(key[11:8])
                        4'h0:HEX2     = `ZERO;
                        4'h1:HEX2     = `ONE;
                        4'h2:HEX2     = `TWO;
                        4'h3:HEX2     = `THREE;
                        4'h4:HEX2     = `FOUR;
                        4'h5:HEX2     = `FIVE;
                        4'h6:HEX2     = `SIX;
                        4'h7:HEX2     = `SEVEN;
                        4'h8:HEX2     = `EIGHT;
                        4'h9:HEX2     = `NINE;
                        4'hA:HEX2     = `A;
                        4'hB:HEX2     = `B;
                        4'hC:HEX2     = `C;
                        4'hD:HEX2     = `D;
                        4'hE:HEX2     = `E;
                        4'hF:HEX2     = `F;
                        default: HEX2 = `DASH;
                    endcase

                    case(key[15:12])
                        4'h0:HEX3     = `ZERO;
                        4'h1:HEX3     = `ONE;
                        4'h2:HEX3     = `TWO;
                        4'h3:HEX3     = `THREE;
                        4'h4:HEX3     = `FOUR;
                        4'h5:HEX3     = `FIVE;
                        4'h6:HEX3     = `SIX;
                        4'h7:HEX3     = `SEVEN;
                        4'h8:HEX3     = `EIGHT;
                        4'h9:HEX3     = `NINE;
                        4'hA:HEX3     = `A;
                        4'hB:HEX3     = `B;
                        4'hC:HEX3     = `C;
                        4'hD:HEX3     = `D;
                        4'hE:HEX3     = `E;
                        4'hF:HEX3     = `F;
                        default: HEX3 = `DASH;
                    endcase

                    case(key[19:16])
                        4'h0:HEX4     = `ZERO;
                        4'h1:HEX4     = `ONE;
                        4'h2:HEX4     = `TWO;
                        4'h3:HEX4     = `THREE;
                        4'h4:HEX4     = `FOUR;
                        4'h5:HEX4     = `FIVE;
                        4'h6:HEX4     = `SIX;
                        4'h7:HEX4     = `SEVEN;
                        4'h8:HEX4     = `EIGHT;
                        4'h9:HEX4     = `NINE;
                        4'hA:HEX4     = `A;
                        4'hB:HEX4     = `B;
                        4'hC:HEX4     = `C;
                        4'hD:HEX4     = `D;
                        4'hE:HEX4     = `E;
                        4'hF:HEX4     = `F;
                        default: HEX4 = `DASH;
                    endcase

                    case(key[23:20])
                        4'h0:HEX5     = `ZERO;
                        4'h1:HEX5     = `ONE;
                        4'h2:HEX5     = `TWO;
                        4'h3:HEX5     = `THREE;
                        4'h4:HEX5     = `FOUR;
                        4'h5:HEX5     = `FIVE;
                        4'h6:HEX5     = `SIX;
                        4'h7:HEX5     = `SEVEN;
                        4'h8:HEX5     = `EIGHT;
                        4'h9:HEX5     = `NINE;
                        4'hA:HEX5     = `A;
                        4'hB:HEX5     = `B;
                        4'hC:HEX5     = `C;
                        4'hD:HEX5     = `D;
                        4'hE:HEX5     = `E;
                        4'hF:HEX5     = `F;
                        default: HEX5 = `DASH;
                    endcase
                end

                else begin
                    HEX0 = `DASH;
                    HEX1 = `DASH;
                    HEX2 = `DASH;
                    HEX3 = `DASH;
                    HEX4 = `DASH;
                    HEX5 = `DASH;
                end
            end

            default: begin
                // Hold values
            end
        endcase
    end
endmodule
