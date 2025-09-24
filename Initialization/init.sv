`timescale 1ps / 1ps

module init(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            output logic [7:0] addr, output logic [7:0] wrdata, output logic wren);

enum {INITALIZE, WRITE, DONE, ERROR} state;

logic [7:0] addr_math;

always_ff @(posedge clk)begin
    
    if(~rst_n)
        state = INITALIZE;
    
    else begin

        case (state)

            INITALIZE: begin 

                if(en)
                    state = WRITE;
                
                else
                    state = INITALIZE;
            end

            WRITE: begin
                
                if(addr_math === 255)
                    state = INITALIZE;

                else
                    state = WRITE;
            end

            DONE: state = DONE;

            default: state = ERROR;
        endcase
    end

    case (state)
        
        INITALIZE: addr_math = 0;

        WRITE: addr_math = addr_math + 1;
        
        DONE: addr_math = addr_math;

        default: addr_math = 'x;
    endcase
end

always_comb begin
    
    case (state)

        INITALIZE: begin
            
            rdy = 1;
            wren = 1;
        end

        WRITE: begin

            rdy = 0;
            wren = 1;
        end

        DONE: begin
            
            rdy = 1;
            wren = 0;
        end

        default: begin
            
            rdy = 'x;
            wren = 'x;
        end
    endcase

    addr =   addr_math;
    wrdata = addr_math;
end
endmodule: init