`timescale 1ps / 1ps

module task3(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    logic en;
    logic rdy;

    logic [7:0] ct_addr;
    logic [7:0] ct_rddata;
    logic [7:0] ct_wrdata;

    logic [7:0] pt_addr;
    logic [7:0] pt_rddata;
    logic [7:0] pt_wrdata;

    logic ct_wren;
    logic pt_wren;

    ct_mem ct(.address(ct_addr), .clock(CLOCK_50), .data(ct_wrdata), .wren(ct_wren), .q(ct_rddata));
    pt_mem pt(.address(pt_addr), .clock(CLOCK_50), .data(pt_wrdata), .wren(pt_wren), .q(pt_rddata));
    arc4 a4(.clk(CLOCK_50), .rst_n(KEY[3]), .en(en), .rdy(rdy), .key({14'b0, SW[9:0]}), .ct_addr(ct_addr), .ct_rddata(ct_rddata),
            .pt_addr(pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));

   always_comb begin

        HEX0 = '1;
        HEX1 = '1;
        HEX2 = '1;
        HEX3 = '1;
        HEX4 = '1;
        HEX5 = '1;
        LEDR = 10'b0000000000;
        
        ct_wren = 0;
        ct_wrdata = 0;

        if(rdy)
            en = 1;

        else
            en = 0;
    end

endmodule: task3
