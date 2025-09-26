/* 
--- File:    tb_rtl_top_arc4.sv
--- Module:  tb_rtl_top_arc4
--- Brief:   Testbench for top_arc4; loads CT image, applies key via switches, and sanity-checks board I/O defaults.

--- Description:
---   - Generates a 100 MHz clock (#5).
---   - Preloads ciphertext BRAM from "test2.memh".
---   - Drives reset via KEY[3] and sets SW to 0x018.
---   - Asserts seven-seg and LED defaults, then lets ARC4 run for a fixed window.
---   - Exposes internal S/PT/CT memories through hierarchical references for debugging.

--- Interfaces Driven/Monitored:
---   Drives:  CLOCK_50, KEY[3], SW[9:0]
---   Observes: HEX0..HEX5, LEDR, internal memories

--- Author: Joey Negm
*/

`timescale 1ps / 1ps

module tb_rtl_top_arc4();

    // --- Top Level Mirrors ---
    logic       CLOCK_50;
    logic [3:0] KEY;
    logic [9:0] SW;
    logic [6:0] HEX0;
    logic [6:0] HEX1;
    logic [6:0] HEX2;
    logic [6:0] HEX3;
    logic [6:0] HEX4;
    logic [6:0] HEX5;
    logic [9:0] LEDR;
    logic       err;

    // --- Internal Memories ---
    logic [7:0] s [0:255];
    logic [7:0] pt [0:255];
    logic [7:0] ct [0:255];

    // --- Instantiate DUT ---
    top_arc4 dut(.*);

    // --- Hierarchical Assigns ---
    assign s   = dut.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data;
    assign pt  = dut.pt.altsyncram_component.m_default.altsyncram_inst.mem_data;
    assign ct  = dut.ct.altsyncram_component.m_default.altsyncram_inst.mem_data;

    // --- Clock ---
    always #5 CLOCK_50 = ~CLOCK_50;

    initial begin
        //initial delay
        #10

        $readmemh("test2.memh", dut.ct.altsyncram_component.m_default.altsyncram_inst.mem_data);
        SW       = 10'h000018;
        err      = 1'b0;
        CLOCK_50 = 1'b0;
        KEY[3]   = 1'b0;

        //cycle
        #10

        assert(HEX0 === 7'b1111111);
        assert(HEX1 === 7'b1111111);
        assert(HEX2 === 7'b1111111);
        assert(HEX3 === 7'b1111111);
        assert(HEX4 === 7'b1111111);
        assert(HEX5 === 7'b1111111);
        assert(LEDR === '0);

        KEY[3] = 1'b1;

        //cycle
        #100000

        if(err)
            $error("FAILED");
        else
            $display("PASSED");
            
        $stop;
    end
endmodule
