`timescale 1ps / 1ps

module tb_rtl_task5();

logic CLOCK_50;
logic [3:0] KEY;
logic [9:0] SW;
logic [6:0] HEX0;
logic [6:0] HEX1;
logic [6:0] HEX2;
logic [6:0] HEX3;
logic [6:0] HEX4;
logic [6:0] HEX5;
logic [9:0] LEDR;
logic err;

logic [7:0] s [0:255];
logic [7:0] pt [0:255];
logic [7:0] ct [0:255];

task5 dut(.*);

assign s  = dut.c.c1.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data;
assign pt  = dut.c.ptdc.altsyncram_component.m_default.altsyncram_inst.mem_data;
assign ct  = dut.ct.altsyncram_component.m_default.altsyncram_inst.mem_data;

always #5 CLOCK_50 = ~CLOCK_50;

initial begin

    //initial delay
    #10

    $readmemh("test_tb.memh", dut.ct.altsyncram_component.m_default.altsyncram_inst.mem_data);
    err = 1'b0;
    CLOCK_50 = 1'b0;
    KEY[3] = 1'b0;

    //cycle
    #10

    KEY[3] = 1'b1;

    //cycle
    #1000000

    if(dut.key_valid)
        $display("Key Found: %h", dut.key);

    else
        $display("Key not found");
        
    $stop;
end

endmodule
