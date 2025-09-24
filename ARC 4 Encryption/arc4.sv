`timescale 1ps / 1ps

module arc4(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

    logic flag_init;
    logic flag_ksa;
    logic flag_prga;

    logic [7:0] address;
    logic [7:0] data_in;
    logic [7:0] data_out;
    logic wren;

    logic [7:0] address_init;
    logic [7:0] data_out_init;
    logic wren_init;
    logic rdy_init;
    logic en_init;

    logic [7:0] address_ksa;
    logic [7:0] data_out_ksa;
    logic wren_ksa;
    logic rdy_ksa;
    logic en_ksa;

    logic [7:0] s_addr;
    logic [7:0] s_wrdata;
    logic s_wren;
    logic rdy_prga;
    logic en_prga;


    enum {INITALIZE, INIT, KSA, PRGA, ERROR} task_state;

    s_mem s(.address(address), .clock(clk), .data(data_in), .wren(wren), .q(data_out));

    init initialize(.clk(clk), .rst_n(rst_n), .en(en_init), .rdy(rdy_init), .addr(address_init), .wrdata(data_out_init), .wren(wren_init));

    ksa keyschedule(.clk(clk), .rst_n(rst_n), .en(en_ksa), .rdy(rdy_ksa), .key(key), .addr(address_ksa),
     .rddata(data_out), .wrdata(data_out_ksa), .wren(wren_ksa));

    prga p(.clk(clk), .rst_n(rst_n), .en(en_prga), .rdy(rdy_prga), .key(key), .s_addr(s_addr), .s_rddata(data_out), .s_wrdata(s_wrdata), .s_wren(s_wren),
     .ct_addr(ct_addr), .ct_rddata(ct_rddata), .pt_addr(pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));

    always_ff @(posedge clk) begin

        if(~rst_n) begin
            task_state <= INITALIZE;
            flag_init <= 0;
            flag_ksa <= 0;
            flag_prga <= 0;
        end
        
        else begin
            case(task_state)
                
                INITALIZE: begin

                    if(en)
                        task_state <= INIT;

                    else
                        task_state <= INITALIZE;
                end

                INIT: begin

                    if(flag_init && rdy_init)
                        task_state <= KSA;

                    else
                        task_state <= INIT;
                end

                KSA: begin 
                    
                    if(flag_ksa && rdy_ksa)
                        task_state <= PRGA;

                    else
                        task_state <= KSA;
                end
                
                PRGA: begin 
                    if(rdy_prga && flag_prga)
                        task_state <= INITALIZE;

                    else
                        task_state <= PRGA;
                end

                default: task_state <= ERROR;
            endcase

            case(task_state)

                INITALIZE: begin

                    flag_init <= 0;
                    flag_ksa <= 0;
                    flag_prga <= 0;                    
                end

                INIT: begin

                    if(rdy_init === 0)
                        flag_init <= 1;
                end

                KSA: begin 

                    flag_init <= 0;

                    if(rdy_ksa === 0)
                        flag_ksa <= 1;
                end

                PRGA: begin 
                    
                    flag_ksa <= 0;

                    if(rdy_prga === 0)
                        flag_prga <= 1;
                end

                default: begin
                    flag_init <= 'x;
                    flag_ksa <= 'x;
                end
            endcase
        end 
    end

    always_comb begin

        case(task_state)

            INITALIZE: begin

                rdy = 1'b1;
                en_init = 1'b0;

                en_init = 1'b0;

                wren = 0;
                data_in = 0;
                address = 0;

                en_prga = 1'b0;
                en_ksa = 1'b0;
            end

            INIT: begin
                
                rdy = 1'b0;

                if(~flag_init)
                    en_init = 1'b1;

                else
                    en_init = 1'b0;

                wren = wren_init;
                data_in = data_out_init;
                address = address_init;

                en_prga = 1'b0;
                en_ksa = 1'b0;
            end

            KSA: begin

                rdy = 1'b0;

                if(flag_init)
                    en_ksa = 1'b1;
    
                else
                    en_ksa = 1'b0;

                wren = wren_ksa;
                data_in = data_out_ksa;
                address = address_ksa;

                en_prga = 1'b0;
                en_init = 1'b0;
            end

            PRGA: begin

                rdy = 1'b0;

                if(flag_ksa)
                    en_prga = 1'b1;
                    
                else
                    en_prga = 1'b0;
                
                en_ksa = 1'b0;
                en_init = 1'b0;

                wren = s_wren;
                data_in = s_wrdata;
                address = s_addr;
            end

            default: begin

                    rdy = 1'bx;
                    en_init = 1'bx;
                    en_ksa = 1'bx;
                    wren = 1'bx;
                    data_in = 'x;
                    address = 'x;
                    en_prga = 1'bx;  
            end
        endcase
    end
endmodule: arc4
