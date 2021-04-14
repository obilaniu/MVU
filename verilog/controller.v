/**
 * Controller
 */

`timescale 1ns/1ps

/**** Module ****/
module controller #(
    parameter   BCNTDWN = 29                            // Bitwidth of the countdown port
)
(
    input   wire                    clk,                // Clock signal
    input   wire                    clr,                // Clears the internal state
    input   wire                    start,              // Pulse to start the MVU task
    input   wire[BCNTDWN-1 : 0]     countdown,          // Number of clock cycles for the task
    input   wire                    step,               // Count down if 1. Used for stalling.
    output  wire                    run,                // Indicates that the task is running
    output  wire                    done,               // Indicates that the task is done
    output  wire                    irq                 // Interrupt request to the embedded CPU
);

// State encoding
localparam
    ST_IDLE     = 3'b001,
    ST_RUN      = 3'b010,
    ST_DONE     = 3'b100;


// Registers and wires
reg     [BCNTDWN-1 : 0]     counter_q;                  // Countdown counter
reg                         done_q;                     // Done signal
reg     [2:0]               state;                      // State
reg     [2:0]               nextstate;                  // Next state


//
// State machine: next state
//
always @(state, counter_q, start) begin

    // State machine transitions
    case (state)

        ST_IDLE:
            // If the start pulse is raised, go to run state
            if (start) begin
                nextstate = ST_RUN;
            end else begin
                nextstate = ST_IDLE;
            end

        ST_RUN:
            // If the countdown is at 0, then move to done state
            if (counter_q == 1) begin
                nextstate = ST_DONE;
            end else begin
                nextstate = ST_RUN;
            end

        ST_DONE:
            nextstate = ST_IDLE;

        default:
            nextstate = ST_IDLE;
    endcase

end

//
// State machine: clock in the state
//
always @(posedge clk) begin
    if (clr) begin
        state <= ST_IDLE;
    end else begin
        state <= nextstate;
    end
end


// Countdown
always @(posedge clk) begin

    if (clr) begin

        // Clear registers
        counter_q = 0;

    end else begin

        case (state)

            ST_IDLE:
                counter_q <= countdown;

            ST_RUN:
                if (step) begin
                    counter_q <= counter_q - 1;
                end
            
            default:
                counter_q <= countdown;            

        endcase
    end
end


// Done signal
always @(posedge clk) begin
    
    if (clr) begin

        // Reset
        done_q <= 0;

    end else begin
        
        case (state)
            
            ST_IDLE:
                if (start) begin
                    done_q <= 0;
                end

            ST_RUN:
                if (nextstate == ST_DONE) begin
                    done_q <= 1;
                end

            default:
                done_q <= done_q;

        endcase

    end

end


// Combinational signals
assign irq = state == ST_DONE ? 1 : 0;
assign run = state == ST_RUN ? 1 : 0;

// Output port mappings
assign done = done_q;


endmodule