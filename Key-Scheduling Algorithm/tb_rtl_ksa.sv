`timescale 1ps / 1ps

module tb_rtl_ksa();

    // Inputs
    logic clk;
    logic rst_n;
    logic en;
    logic [23:0] key;

    // Outputs
    logic rdy;
    logic [7:0] addr;
    logic [7:0] rddata;
    logic [7:0] wrdata;
    logic wren;
    logic [7:0] s [0:255];

    // Variables
    logic [7:0] temp;
    logic [8:0] counter;
    logic [7:0] i;
    logic [7:0] j;
    logic [7:0] keylength;
    logic err;

    // Instantiate the ksa module
    ksa dut(.*);

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        rddata = 0;
        key[23:10] = 0;
        key[9:0] = 10'h00033C;
        keylength = 3;
        clk = 1'b0;
        $readmemh("init.mem", s);
        rst_n = 1'b0;
        err = 1'b0;
        j = 0;

        // Cycle Initalize

        #10

        en = 1'b1;
        rst_n = 1'b1;

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

        assert(wren === 1'b0)
            $display("wren is correct - INITIALIZE");

        else begin

            $error("wren is INCORRECT - INITIALIZE");
            err = 1'b1;
        end

        for(counter = 0; counter <= 255; counter = counter + 1) begin
            
            i = counter[7:0];
            #10 //Read_i

            assert(wren === 0);
            assert(addr === i);
            assert(rdy === 0);
            assert(wrdata === 0);

            #10 //Wait_i
            assert(wren === 0);
            assert(addr === 0);
            assert(rdy === 0);
            assert(wrdata === 0);

            rddata = s[i];       

            #10 //Read_j

            assert(wren === 0);
            assert(rdy === 0);
            assert(wrdata === 0);
            
            temp = s[i];

            case (i % 3)
                0: j = (j + temp + key[23:16]) % 256; // uses the leftmost 4 bits
                1: j = (j + temp + key[15:8]) % 256;  // uses the middle 4 bits
                2: j = (j + temp + key[7:0]) % 256;  // uses the rightmost 4 bits
            endcase   

            assert(addr === j);
            #10 //Wait_j

            assert(wren === 0);
            assert(addr === 0);
            assert(rdy === 0);
            assert(wrdata === 0);

            rddata = s[j];

            #10 //Write_i

            assert(wren === 1'b1);
            assert(addr === i);
            assert(rdy === 0);


            s[i] = wrdata;

            assert(wrdata === s[j])
                $display("s_i write is CORRECT || i = %d ", i);

            else begin

                $error("s_i write is INCORRECT || i = %d ", i);
                err = 1'b1;
            end

            #10 //Write_j

            assert(wren === 1);
            assert(addr === j);
            assert(rdy === 0);

            s[j] = wrdata;

            assert(wrdata === temp)
                $display("s_j write is CORRECT || i = %d ", i);

            else begin

                $error("s_j write is INCORRECT || i = %d ", i);
                err = 1'b1;
            end

        end

        assert(~err)
            $display("Test Passed");
        else
            $error("Test Failed");
        
        $stop;
    end
endmodule