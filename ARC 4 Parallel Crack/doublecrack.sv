/* 
--- File:    doublecrack.sv
--- Module:  doublecrack
--- Brief:   Dual-key brute-force wrapper that runs two 'crack' engines in parallel and writes out the found plaintext.

--- Description:
---   Instantiates two 'crack' modules starting from different initial key seeds (0 and 1). Whichever
---   engine asserts key_valid first becomes the source for the plaintext stream, which is copied into
---   a local pt_mem. The wrapper exposes the discovered key and a ready flag passthrough.

--- Interfaces:
---   clk, rst_n          : Clock and active-low reset.
---   en, rdy             : Start and ready handshake (rdy mirrors c1).
---   key, key_valid      : Output selected discovered key and its validity.
---   ct_addr/ct_rddata   : Ciphertext memory interface (shared by both crack engines).

--- Author: Joey Negm
*/

`timescale 1ps / 1ps

module doublecrack(
	input  logic 	    clk, 
	input  logic 	    rst_n,
    input  logic 	    en, 
	output logic 	    rdy,
    output logic [23:0] key, 
	output logic 	    key_valid,
    output logic [7:0]  ct_addr, 
	input  logic [7:0]  ct_rddata
	);
    
	// --- PT memory interface ---
	logic [7:0] pt_addr;
	logic [7:0] pt_rddata;
	logic [7:0] pt_wrdata;
	logic 		pt_wren;

	// --- Crack engine 1 ---
	logic [23:0] key_c1;
	logic [7:0]  ct_addr_c1;
	logic [7:0]  pt_addr_c1;
	logic [7:0]  pt_rddata_c1;
	logic [1:0]  key_inital_c1;
	logic        rdy_c1;
	logic        key_valid_c1;

	// --- Crack engine 2 ---
	logic [23:0] key_c2;
	logic [7:0]  ct_addr_c2;
	logic [7:0]  pt_rddata_c2;
	logic [7:0]  pt_addr_c2;
	logic [1:0]  key_inital_c2;
	logic        rdy_c2;
	logic        key_valid_c2;

	// --- State machine ---
	enum {WAIT, READ_pt_c1, READ_pt_c2, WRITE_pt, DONE, ERROR} state;

	// --- Module instantiations ---
    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem ptdc(.address(pt_addr), .clock(clk), .data(pt_wrdata), .wren(pt_wren), .q(pt_rddata));

    crack c1(.clk(clk), .rst_n(rst_n), .en(rst_n), .rdy(rdy_c1), .key(key_c1), .key_valid(key_valid_c1), .ct_addr(ct_addr_c1),
			 .ct_rddata(ct_rddata), .key_inital(key_inital_c1), .pt_addr_in(pt_addr_c1), .pt_rddata(pt_rddata_c1));
    crack c2(.clk(clk), .rst_n(rst_n), .en(rst_n), .rdy(rdy_c2), .key(key_c2), .key_valid(key_valid_c2), .ct_addr(ct_addr_c2), 
			 .ct_rddata(ct_rddata), .key_inital(key_inital_c2), .pt_addr_in(pt_addr_c2), .pt_rddata(pt_rddata_c2));
	
	// --- Ongoing Assignments ---
	assign rdy 			 = rdy_c1;
	assign key_inital_c1 = 2'd0;
	assign key_inital_c2 = 2'd1;
	assign ct_addr 		 = ct_addr_c1;

	// --- Sequential: state & registers updates ---
	always_ff @(posedge clk) begin
		if(~rst_n) begin
			state   <= WAIT;
			pt_addr = 8'd0;
		end
		else begin
			case(state)
				WAIT: begin
					if(key_valid_c1) 
						state <= READ_pt_c1;
					else if(key_valid_c2)
						state <= READ_pt_c2;
					else
						state <= WAIT;
				end

				READ_pt_c1: state <= WRITE_pt;
				READ_pt_c2: state <= WRITE_pt;
				
				WRITE_pt: begin
					if(pt_addr_c1 === 8'd255 || pt_addr_c2 === 8'd255)
						state <= DONE;
					else if(key_valid_c1)
						state <= READ_pt_c1;
					else if(key_valid_c2)
						state <= READ_pt_c2;
					else
						state <= WAIT;
				end

				DONE:    state <= DONE;
				default: state <= ERROR;
			endcase

			case(state)
				WAIT: begin
					pt_addr = 8'd0;
				end

				READ_pt_c1: begin
				// No state updates
				end

				READ_pt_c2: begin
				// No state updates
				end

				WRITE_pt: begin
					pt_addr = pt_addr + 8'd1;
				end

				DONE: begin
					// No state updates
				end

				default: begin
					// No state updates
				end

			endcase
		end
	end

	always_comb begin
		case(state)
			WAIT: begin
				pt_wren    = 1'b0;
				pt_addr_c1 = 8'd0;
				pt_addr_c2 = 8'd0;
				pt_wrdata  = 8'd0;
			end

			READ_pt_c1: begin
				pt_wren    = 1'b0;
				pt_addr_c1 = pt_addr;
				pt_addr_c2 = 8'd0;
				pt_wrdata  = 8'd0;
			end

			READ_pt_c2: begin
				pt_wren    = 1'b0;
				pt_addr_c1 = 8'd0;
				pt_addr_c2 = pt_addr;
				pt_wrdata  = 8'd0;
			end

			WRITE_pt: begin
				pt_wren    = 1'b1;
				pt_addr_c1 = 8'd0;
				pt_addr_c2 = 8'd0;

				if(key_valid_c1)
					pt_wrdata = pt_rddata_c1;
				else if(key_valid_c2)
					pt_wrdata = pt_rddata_c2;
				else
					pt_wrdata = 8'd0;
			end

			DONE: begin
				pt_wren    = 1'b0;
				pt_addr_c1 = 8'd0;
				pt_addr_c2 = 8'd0;
				pt_wrdata  = 8'd0;
			end

			default: begin
				pt_wren    = 'x;
				pt_addr_c1 = 'x;
				pt_addr_c2 = 'x;
				pt_wrdata  = 'x;
			end
		endcase

		if (key_valid_c1) begin
			key_valid = 1'b1;
			key       = key_c1;
		end
		else if (key_valid_c2) begin
			key_valid = 1'b1;
			key       = key_c2;
		end
		else begin
			key_valid = 1'b0;
			key       = 24'd0;
		end
	end
    

endmodule: doublecrack