`timescale 1ps / 1ps

module tb_rtl_init();

logic clk;
logic rst_n;
logic en;
logic rdy;
logic [7:0] addr;
logic [7:0] wrdata;
logic wren;
logic err;

/* OUTPUTS:
    rdy
    addr
    wrdata
    wren
*/

init dut(.*);

always #5 clk = ~clk;

initial begin

    err = 1'b0;
    clk = 1'b0;
    rst_n = 1'b0;



    //Cycle
    #10

    rst_n = 1'b1;
    en = 1'b1;

    assert(rdy === 1)
     $display("rdy is correct - INITIALIZE");
     
    else begin
        
        $error("rdy is INCORRECT - INITIALIZE");
        err = 1'b1;
    end


    assert(addr === 0)
     $display("addr is correct - INITIALIZE");
          
    else begin
        
        $error("addr is INCORRECT - INITIALIZE");
        err = 1'b1;
    end


    assert(wrdata === 0)
     $display("wrdata is correct - INITIALIZE");

    else begin
        
        $error("wrdata is INCORRECT - INITIALIZE");
        err = 1'b1;
    end


    assert(wren === 1)
     $display("wren is correct - INITIALIZE");

    else begin
        
        $error("wren is INCORRECT - INITIALIZE");
        err = 1'b1;
    end



    //Cycle
    #10

    en = 1'b0;

    assert(rdy === 0)
     $display("rdy is correct - WRITE - 1");
     
    else begin
        
        $error("rdy is INCORRECT - WRITE - 1");
        err = 1'b1;
    end


    assert(addr === 1)
     $display("addr is correct - WRITE - 1");
          
    else begin
        
        $error("addr is INCORRECT - WRITE - 1");
        err = 1'b1;
    end


    assert(wrdata === 1)
     $display("wrdata is correct - WRITE - 1");

    else begin
        
        $error("wrdata is INCORRECT - WRITE - 1");
        err = 1'b1;
    end


    assert(wren === 1)
     $display("wren is correct - WRITE - 1");

    else begin
        
        $error("wren is INCORRECT - WRITE - 1");
        err = 1'b1;
    end



    //Cycle
    #10



    assert(rdy === 0)
     $display("rdy is correct - WRITE - 2");
     
    else begin
        
        $error("rdy is INCORRECT - WRITE - 2");
        err = 1'b1;
    end


    assert(addr === 2)
     $display("addr is correct - WRITE - 2");
          
    else begin
        
        $error("addr is INCORRECT - WRITE - 2");
        err = 1'b1;
    end


    assert(wrdata === 2)
     $display("wrdata is correct - WRITE - 2");

    else begin
        
        $error("wrdata is INCORRECT - WRITE - 2");
        err = 1'b1;
    end


    assert(wren === 1)
     $display("wren is correct - WRITE - 2");

    else begin
        
        $error("wren is INCORRECT - WRITE - 2");
        err = 1'b1;
    end



    //Cycles
    #3000



    assert(rdy === 0)
     $display("rdy is correct - DONE");
     
    else begin
        
        $error("rdy is INCORRECT - DONE");
        err = 1'b1;
    end


    assert(addr === 255)
     $display("addr is correct - DONE");
          
    else begin
        
        $error("addr is INCORRECT - DONE");
        err = 1'b1;
    end


    assert(wrdata === 255)
     $display("wrdata is correct - DONE");

    else begin
        
        $error("wrdata is INCORRECT - DONE");
        err = 1'b1;
    end


    assert(wren === 0)
     $display("wren is correct - DONE");

    else begin
        
        $error("wren is INCORRECT - DONE");
        err = 1'b1;
    end

    if(err)
        $error("FAILED");

    else
        $display("PASSED");
    
    $stop;
end
endmodule: tb_rtl_init
