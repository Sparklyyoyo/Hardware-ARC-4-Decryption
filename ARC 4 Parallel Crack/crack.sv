`timescale 1ps / 1ps

module crack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata, 
             input logic [1:0] key_inital, input logic [7:0] pt_addr_in, 
             output logic [7:0] pt_rddata);

    //Readable from 32 - 126 inclusive ('h20 - 'h7E)

    enum {INITALIZE, READ_message_length, New_Key, Crack_Key, No_Key_Found, Key_Found, ERROR} state;
    
    logic [7:0] pt_addr_a4;
    logic [7:0] pt_addr;
    logic [7:0] pt_wrdata;
    logic [23:0] key_math;
    logic [7:0] message_length;
    logic pt_wren;
    logic pt_wren_a4;
    logic newkey_flag;
    logic [7:0] ct_addr_a4;
    logic en_a4;
    logic rdy_a4;
    logic flag_pt_wren;
    logic rst_a4;
    

    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem ptc(.address(pt_addr), .clock(clk), .data(pt_wrdata), .wren(pt_wren), .q(pt_rddata));
    arc4 a4(.clk(clk), .rst_n(rst_n), .en(en_a4), .rdy(rdy_a4), .key(key), .ct_addr(ct_addr_a4), .ct_rddata(ct_rddata),
     .pt_addr(pt_addr_a4), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren_a4));


    always_ff @(posedge clk) begin

        if(~rst_n) begin
            state <= INITALIZE;
            newkey_flag <= 1;
            key_math <= key_inital;
            message_length <= 0;
        end

        else begin
            case(state)

                INITALIZE: begin

                    if(en) begin
                        state <= READ_message_length;
                    end

                    else begin
                        state <= INITALIZE;
                    end
                end

                READ_message_length: state <= New_Key;

                New_Key: begin
                        
                    if(rdy_a4) begin
                        state <= Crack_Key;
                    end

                    else begin
                        state <= New_Key;
                    end
                end

                Crack_Key: begin
                    
                    if(((pt_wrdata < 8'h20) || (pt_wrdata > 8'h7E)) && pt_wren) begin
                        state <= New_Key;
                    end

                    else if(pt_addr < message_length) begin
                        state <= Crack_Key;
                    end

                    else
                        state <= Key_Found;
                end

                No_Key_Found: begin
                    state <= No_Key_Found;
                end

                Key_Found: begin
                    state <= Key_Found;
                end

                default: state <= ERROR;
            endcase

            case (state)

                INITALIZE: begin
                    newkey_flag <= 1;
                    key_math <= key_inital;
                    message_length <= 0;
                end

                READ_message_length: begin
                end

                New_Key: begin
                    
                    if(message_length === 0) begin
                        message_length <= ct_rddata;
                    end

                    if(newkey_flag) begin

                        key_math <= key_math + 2;
                    end

                    flag_pt_wren <= 0;
                    newkey_flag <= 0;
                end

                Crack_Key: begin

                    newkey_flag <= 1;

                    if(pt_wren) begin
                        flag_pt_wren <= 1;
                    end

                    if(flag_pt_wren) begin
                    end
                end

                No_Key_Found: begin
                end

                Key_Found: begin
                end

                default:state <= ERROR; 
            endcase
        end
    end

    /* Outputs
    ct_addr
    key_valid
    rdy
    key
    */
always_comb begin
    
    case (state)

        INITALIZE: begin
            key_valid = 0;
            rdy = 1;
            key = key_math;
            ct_addr = 0;
            en_a4 = 0;
            rst_a4 = 0;
            pt_addr = pt_addr_a4;
            pt_wren = pt_wren_a4;
        end

        READ_message_length: begin
            key_valid = 0;
            rdy = 0;
            key = key_math;
            ct_addr = 0;
            en_a4 = 0;
            rst_a4 = 1;
            pt_addr = pt_addr_a4;
            pt_wren = pt_wren_a4;
        end

        New_Key: begin

            key_valid = 0;
            rdy = 0;
            key = key_math;
            ct_addr = ct_addr_a4;
            en_a4 = 0;
            rst_a4 = 0;
            pt_addr = pt_addr_a4;
            pt_wren = pt_wren_a4;
        end

        Crack_Key: begin
                
            key_valid = 0;
            rdy = 0;
            key = key_math;
            ct_addr = ct_addr_a4;
            en_a4 = 1;
            rst_a4 = 1;
            pt_addr = pt_addr_a4;
            pt_wren = pt_wren_a4;
        end

        No_Key_Found: begin

            key_valid = 0;
            rdy = 1;
            key = key_math;
            ct_addr = ct_addr_a4;
            en_a4 = 0;
            rst_a4 = 1;
            pt_addr = pt_addr_a4;
            pt_wren = pt_wren_a4;
        end

        Key_Found: begin

            key_valid = 1;
            rdy = 1;
            key = key_math;
            ct_addr = ct_addr_a4;
            en_a4 = 0;
            rst_a4 = 1;
            pt_addr = pt_addr_in;
            pt_wren = 0;
        end

        default: begin
            key_valid = 'x;
            rdy = 'x;
            key = 'x;
            ct_addr = ct_addr_a4;
            en_a4 = 'x;
            rst_a4 = 'x;
            pt_addr = pt_addr_a4;
            pt_wren = pt_wren_a4;
        end
    endcase
end
endmodule: crack
