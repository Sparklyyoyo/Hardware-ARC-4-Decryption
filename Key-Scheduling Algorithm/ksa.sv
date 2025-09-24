`timescale 1ps / 1ps

module ksa(input logic clk, input logic rst_n,
           input logic en, output logic rdy,
           input logic [23:0] key,
           output logic [7:0] addr, input logic [7:0] rddata, output logic [7:0] wrdata, output logic wren);

    logic [7:0] i;
    logic [7:0] s_i;
    logic [7:0] temp_si;
    logic [7:0] j;
    logic [7:0] s_j;
    logic [7:0] counter;

    enum {INITALIZE, READ_i, READ_j, WAIT_i, WAIT_j, WRITE_i, WRITE_j, ERROR} state;

    always_ff @(posedge clk) begin
    
        if(~rst_n) begin
            state <= INITALIZE;
            counter <= 0;
            i <= 0;
            j <= 0;
            s_i <= 0;
            s_j <= 0;
        end
        
        else begin

            case (state)

                INITALIZE: begin 

                    if(en)
                        state <= READ_i;
                    
                    else
                        state <= INITALIZE;
                end

                READ_i: state <= READ_j;

                //WAIT_i: state = READ_j;

                READ_j: state <= WRITE_i;

                //WAIT_j: state = WRITE_i;

                WRITE_i: state <= WRITE_j;

                WRITE_j: begin
                    
                    if(counter < 255)
                        state <= READ_i;

                    else
                        state <= INITALIZE;
                end

                default: state <= ERROR;
            endcase

            case (state)

                INITALIZE: begin
                    
                    counter <= 0;
                    i <= 0;
                    j <= 0;
                    s_i <= 0;
                    s_j <= 0;
                end
                
                READ_j: begin 

                    i <= i;
                    s_i <= rddata;

                    case (i % 3)
                        0: j <= (j + temp_si + key[23:16]) % 256;
                        1: j <= (j + temp_si + key[15:8]) % 256;
                        2: j <= (j + temp_si + key[7:0]) % 256;
                    endcase

                    s_j <= s_j;
                end

                WRITE_i: begin

                    i <= i;
                    j <= j;
                    s_i <= s_i;
                    s_j <= rddata;
                end

                WRITE_j: begin
                    
                    j <= j;
                    s_i <= s_i;
                    i <= i + 1;
                    counter <= counter + 1;
                    s_j <= s_j;
                end

                default: begin

                    i <= i;
                    j <= j;
                    s_i <= s_i;
                    s_j <= s_j;
                end
            endcase
        end
    end

    /* Outputs

        rdy
        addr
        wrdata
        wren
    */

    always_comb begin

        case (state)

            INITALIZE: begin

                rdy = 1'b1;
                addr = 0;
                wrdata = 0;
                wren = 0;
                temp_si = 'x;
            end

            READ_i: begin

                rdy = 0;
                addr = i;
                wrdata = 0;
                wren = 0;
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

                rdy = 0;
                wrdata = 0;
                wren = 0;
            end

            WRITE_i: begin

                rdy = 0;
                addr = i;
                wrdata = rddata;
                wren = 1;
                temp_si = 'x;
            end

            WRITE_j: begin

                rdy = 0;
                addr = j;
                wrdata = s_i;
                wren = 1;
                temp_si = 'x;
            end

            default: begin
                
                rdy = 0;
                addr = 0;
                wrdata = 0;
                wren = 0;
                temp_si = 'x;
            end
        endcase   
    end
endmodule: ksa
