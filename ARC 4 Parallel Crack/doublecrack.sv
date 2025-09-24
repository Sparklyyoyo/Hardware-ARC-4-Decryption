module doublecrack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata);

    // your code here
    
	logic [7:0] pt_addr;
	logic [7:0] pt_rddata;
	logic [7:0] pt_wrdata;
	logic pt_wren;

	logic [23:0] key_c1;
	logic [7:0] ct_addr_c1;
	logic [7:0] pt_addr_c1;
	logic [7:0] pt_rddata_c1;
	logic [1:0] key_inital_c1;
	logic rdy_c1;
	logic key_valid_c1;

	logic [23:0] key_c2;
	logic [7:0] ct_addr_c2;
	logic [7:0] pt_rddata_c2;
	logic [7:0] pt_addr_c2;
	logic [1:0] key_inital_c2;
	logic rdy_c2;
	logic key_valid_c2;
	
	enum {WAIT, READ_pt_c1, READ_pt_c2, WRITE_pt, DONE, ERROR} state;

    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem ptdc(.address(pt_addr), .clock(clk), .data(pt_wrdata), .wren(pt_wren), .q(pt_rddata));

    // for this task only, you may ADD ports to crack
    crack c1(.clk(clk), .rst_n(rst_n), .en(rst_n), .rdy(rdy_c1), .key(key_c1), .key_valid(key_valid_c1), .ct_addr(ct_addr_c1),
			 .ct_rddata(ct_rddata), .key_inital(key_inital_c1), .pt_addr_in(pt_addr_c1), .pt_rddata(pt_rddata_c1));
    crack c2(.clk(clk), .rst_n(rst_n), .en(rst_n), .rdy(rdy_c2), .key(key_c2), .key_valid(key_valid_c2), .ct_addr(ct_addr_c2), 
			 .ct_rddata(ct_rddata), .key_inital(key_inital_c2), .pt_addr_in(pt_addr_c2), .pt_rddata(pt_rddata_c2));
	
	assign rdy = rdy_c1;
	assign key_inital_c1 = 0;
	assign key_inital_c2 = 1;
	assign ct_addr = ct_addr_c1;

	always_ff @(posedge clk) begin

		if(~rst_n) begin
			state <= WAIT;
			pt_addr = 0;
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

				READ_pt_c1: begin
					
					state <= WRITE_pt;
				end

				READ_pt_c2: begin

					state <= WRITE_pt;
				end

				WRITE_pt: begin

					if(pt_addr_c1 === 255 || pt_addr_c2 === 255)
						state <= DONE;
					
					else if(key_valid_c1)
						state <= READ_pt_c1;

					else if(key_valid_c2)
						state <= READ_pt_c2;

					else
						state <= WAIT;
				end

				DONE: state <= DONE;

				default: state <= ERROR;
			endcase

			case(state)

				WAIT: begin

					pt_addr = 0;
				end

				READ_pt_c1: begin

				end

				READ_pt_c2: begin

				end

				WRITE_pt: begin

					pt_addr = pt_addr + 1;
				end

				DONE: begin

				end

				default: begin
				end

			endcase
		end
	end

	always_comb begin

		case(state)

			WAIT: begin

				pt_wren = 0;
				pt_addr_c1 = 0;
				pt_addr_c2 = 0;
				pt_wrdata = 0;
			end

			READ_pt_c1: begin
				
				pt_wren = 0;
				pt_addr_c1 = pt_addr;
				pt_addr_c2 = 0;
				pt_wrdata = 0;
			end

			READ_pt_c2: begin
				
				pt_wren = 0;
				pt_addr_c1 = 0;
				pt_addr_c2 = pt_addr;
				pt_wrdata = 0;
			end

			WRITE_pt: begin
				
				pt_wren = 1;
				pt_addr_c1 = 0;
				pt_addr_c2 = 0;

				if(key_valid_c1)
					pt_wrdata = pt_rddata_c1;

				else if(key_valid_c2)
					pt_wrdata = pt_rddata_c2;

				else
					pt_wrdata = 0;
			end

			DONE: begin

				pt_wren = 0;
				pt_addr_c1 = 0;
				pt_addr_c2 = 0;
				pt_wrdata = 0;
			end

			default: begin

				pt_wren = 'x;
				pt_addr_c1 = 'x;
				pt_addr_c2 = 'x;
				pt_wrdata = 'x;
			end
		endcase

		if (key_valid_c1) begin
			key_valid = 1;
			key = key_c1;
		end

		else if (key_valid_c2) begin
			key_valid = 1;
			key = key_c2;
		end

		else begin
			key_valid = 0;
			key = 0;
		end
	end
    

endmodule: doublecrack