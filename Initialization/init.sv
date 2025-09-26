// --- File:    init.sv
// --- Module:  init
// --- Brief:   Simple initialization sequencer that increments an address/data byte while enabled.
//
// --- Description:
// ---   State machine: INITALIZE → WRITE → (loops until addr_math===255) → INITALIZE.
// ---   Exposes addr/wrdata mirrors of the internal counter and drives rdy/wren per state.
//
// --- Interfaces:
// ---   clk, rst_n  : Clock and active-low reset.
// ---   en, rdy     : Enable input; ready output.
// ---   addr        : Current byte address (mirrors addr_math).
// ---   wrdata      : Write data byte (same as addr).
// ---   wren        : Write enable indicator.
//
// --- Author: Joey Negm

`timescale 1ps / 1ps

module init(
    input  logic       clk, 
    input  logic       rst_n,
    input  logic       en, 
    output logic       rdy,
    output logic [7:0] addr, 
    output logic [7:0] wrdata, 
    output logic       wren
    );

    enum {INITALIZE, WRITE, DONE, ERROR} state;

    logic [7:0] addr_math;

    // --- Sequential: state & addr_math updates ---
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

    // --- Combinational: outputs ---
    always_comb begin
        case (state)
            INITALIZE: begin
                rdy = 1'b1;
                wren = 1'b1;
            end

            WRITE: begin
                rdy = 1'b0;
                wren = 1'b1;
            end

            DONE: begin
                rdy = 1'b1;
                wren = 1'b0;
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