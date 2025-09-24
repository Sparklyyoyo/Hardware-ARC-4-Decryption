`timescale 1ps / 1ps

module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

    logic [7:0] pad [0:255];

    logic [7:0] i;
    logic [7:0] s_i;

    logic [7:0] j;
    logic [7:0] s_j;

    logic [7:0] k;
    logic [7:0] ct_k;
    logic [7:0] temp_si;
    logic [7:0] temp_sj;
    logic [7:0] si_sj;
    logic [7:0] message_length;
    logic flag;
    logic READ_i_NEXT;
    logic WRITE_pt_NEXT;

    enum {INITALIZE, READ_message_length, READ_i, READ_j, READ_si_sj, WRITE_i, WRITE_j, WRITE_pt, READ_ct, ERROR} state;

    always_ff @(posedge clk) begin
        
        if(~rst_n) begin
            state <= INITALIZE;
            i <= 0;
            j <= 0;
            s_i <= 0;
            s_j <= 0;
            k <= 1;
            si_sj <= 0;
            flag <= 0;
            ct_k <= 0;
            message_length <= 0;
            READ_i_NEXT <= 0;
            WRITE_pt_NEXT <= 0;
        end
            
            else begin
    
                case (state)
    
                    INITALIZE: begin 
    
                        if(en)
                            state <= READ_message_length;
                        
                        else
                            state <= INITALIZE;
                    end

                    READ_message_length: state <= READ_i;

                    READ_i: state <= READ_j;
    
                    READ_j: state <= WRITE_i;
                    
                    WRITE_i: state <= WRITE_j;

                    WRITE_j: state <= READ_si_sj;
    
                    READ_si_sj: begin

                        if(k < message_length) begin
                            state <= READ_i;
                            READ_i_NEXT = 1;
                        end

                        else begin
                            state <= WRITE_pt;
                            WRITE_pt_NEXT = 1;
                        end
                    end
    
                    WRITE_pt: begin
                                                
                        if(k < message_length)
                            state <= READ_ct;
    
                        else
                            state <= INITALIZE;
                    end
    
                    READ_ct: state <= WRITE_pt;

                    default: state <= ERROR;
                endcase

                case (state)

                    INITALIZE: begin
                        
                        i <= 0;
                        j <= 0;
                        k <= 1;
                        s_i <= 0;
                        s_j <= 0;
                        flag <= 0;
                        si_sj <= 0;
                        ct_k <= 0;
                        message_length <= 0;
                        READ_i_NEXT = 0;
                        WRITE_pt_NEXT = 0;
                    end

                    READ_message_length: begin
                    end

                    READ_i: begin
                        
                        if(READ_i_NEXT === 1) begin
                            pad[k - 1] <= s_rddata;
                            si_sj <= s_rddata;
                        end
                        
                        READ_i_NEXT = 0;
                        message_length <= ct_rddata;
                        i <= (i + 1) % 256;
                    end

                    READ_j: begin

                        s_i <= s_rddata;
                        j <= (j + temp_si) % 256;
                    end

                    WRITE_i: begin

                        s_j <= s_rddata;
                    end

                    WRITE_j: begin
    
                    end

                    READ_si_sj: begin
                        
                        if(k === message_length)
                            k <= 1;
                        
                        else 
                            k <= k + 1;
                    end

                    WRITE_pt: begin
                        if(WRITE_pt_NEXT === 1)
                            pad[message_length] <= s_rddata;
                        
                        WRITE_pt_NEXT = 0;

                        if(flag === 0) begin
                            flag = 1;
                        end

                        else begin
                            ct_k <= ct_rddata;
                            k <= k + 1;
                        end
                    end

                    READ_ct: begin

                    end

                    //Write a default state that does nothing but keep the values the same
                    default: begin

                        i <= i;
                        j <= j;
                        s_i <= s_i;
                        s_j <= s_j;
                        k <= k;
                        si_sj <= si_sj;
                        flag <= flag;
                        ct_k <= ct_k;
                        message_length <= message_length;
                    end
                endcase
            end
    end

    //Write an always comb block for the outputs

    always_comb begin
        
        case (state)
    
            INITALIZE: begin
    
                rdy = 1'b1;
                s_addr = 0;
                s_wrdata = 0;
                s_wren = 0;

                ct_addr = 0;

                pt_addr = 0;
                pt_wrdata = 0;
                pt_wren = 0;

                temp_si = 0;
                temp_sj = 0;
            end

            READ_message_length: begin

                rdy = 0;
                s_addr = 0;
                s_wrdata = 0;
                s_wren = 0;

                ct_addr = 0;

                pt_addr = 0;
                pt_wrdata = 0;
                pt_wren = 0;

                temp_si = 0;
                temp_sj = 0;
            end

            READ_i: begin
    
                rdy = 0;
                s_addr = (i + 1) % 256;
                s_wrdata = 0;
                s_wren = 0;

                ct_addr = 0;

                pt_addr = 0;
                pt_wrdata = 0;
                pt_wren = 0;

                temp_si = 0;
                temp_sj = 0;
            end
    
            READ_j: begin
                
                temp_si = s_rddata;

                rdy = 0;
                s_addr = (j + temp_si) % 256;
                s_wrdata = 0;
                s_wren = 0;

                ct_addr = 0;

                pt_addr = 0;
                pt_wrdata = 0;
                pt_wren = 0;

                temp_sj = 0;
            end

            READ_si_sj: begin

                rdy = 0;
                s_addr = (s_i + s_j) % 256;
                s_wrdata = 0;
                s_wren = 0;

                ct_addr = 0;

                pt_addr = 0;
                pt_wrdata = 0;
                pt_wren = 0;

                temp_sj = 0;
                temp_si = 0;
            end

            WRITE_i: begin
                
                temp_sj = s_rddata;
                rdy = 0;
                s_addr = i;
                s_wrdata = temp_sj;
                s_wren = 1;

                ct_addr = 0;

                pt_addr = 0;
                pt_wrdata = 0;
                pt_wren = 0;

                temp_si = 0;
                
            end
    
            WRITE_j: begin
    
                rdy = 0;
                s_addr = j;
                s_wrdata = s_i;
                s_wren = 1;

                ct_addr = 0;

                pt_addr = 0;
                pt_wrdata = 0;
                pt_wren = 0;

                temp_si = 0;
                temp_sj = 0;
            end
    
            WRITE_pt: begin
                
                rdy = 0;
                s_addr = 0;
                s_wrdata = 0;
                s_wren = 0;

                ct_addr = 0;

                if(flag === 0) begin
                    pt_addr = 0;
                    pt_wrdata = message_length;
                    pt_wren = 1;
                end

                else begin
                    pt_addr = k;
                    pt_wrdata = pad[k] ^ ct_rddata;
                    pt_wren = 1;
                end

                temp_si = 0;
                temp_sj = 0;
            end
    
            READ_ct: begin
    
                rdy = 0;
                s_addr = 0;
                s_wrdata = 0;
                s_wren = 0;

                ct_addr = k;

                pt_addr = 0;
                pt_wrdata = 0;
                pt_wren = 0;

                temp_si = 0;
                temp_sj = 0;
            end
    
            default: begin
    
                rdy = 'x;
                s_addr = 'x;
                s_wrdata = 'x;
                s_wren = 'x;

                ct_addr = 'x;

                pt_addr = 'x;
                pt_wrdata = 'x;
                pt_wren = 'x;

                temp_si = 'x;
                temp_sj = 'x;
            end
        endcase
    end
endmodule: prga
