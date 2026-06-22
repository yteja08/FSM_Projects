module smart_energy_meter_fsm
#(
    parameter INIT_TICKS = 2,
    parameter LOW_CREDIT_TIMEOUT = 3
)
(
    input  wire clk,
    input  wire rst,
    input  wire sample_tick,
    input  wire overload,
    input  wire tamper_detected,
    input  wire pay_received,
    input  wire low_credit,

    output reg  measure_enable,
    output reg  relay_on,
    output reg  warning,
    output reg  tamper_alarm,
    output reg [2:0] state_dbg
);

    // State encoding
    localparam S_INIT           = 3'd0;
    localparam S_NORMAL         = 3'd1;
    localparam S_LOW_CREDIT     = 3'd2;
    localparam S_DISCONNECTED   = 3'd3;
    localparam S_OVERLOAD_TRIP  = 3'd4;
    localparam S_TAMPER         = 3'd5;

    reg [2:0] state, next_state;

    reg [3:0] init_counter;
    reg [3:0] low_credit_counter;

    //----------------------------------------------------
    // State Register
    //----------------------------------------------------
    always @(posedge clk)
    begin
        if (rst)
            state <= S_INIT;
        else
            state <= next_state;
    end

    //----------------------------------------------------
    // Counters
    //----------------------------------------------------

    always @(posedge clk)
    begin
        if(rst)
            init_counter <= 0;
        else if(state == S_INIT)
        begin
            if(init_counter < INIT_TICKS)
                init_counter <= init_counter + 1;
        end
        else
            init_counter <= 0;
    end

    always @(posedge clk)
    begin
        if(rst)
            low_credit_counter <= 0;

        else if(state == S_LOW_CREDIT)
        begin
            if(low_credit_counter < LOW_CREDIT_TIMEOUT)
                low_credit_counter <= low_credit_counter + 1;
        end
        else
            low_credit_counter <= 0;
    end
    //----------------------------------------------------
    // Next State Logic
    //----------------------------------------------------
    always @(*)
    begin
        next_state = state;

        case(state)

        //------------------------------------------------
        S_INIT:
        begin
            if (init_counter >= INIT_TICKS)
                next_state = S_NORMAL;
        end

        //------------------------------------------------
        S_NORMAL:
        begin
            if (tamper_detected)
                next_state = S_TAMPER;
            else if (overload)
                next_state = S_OVERLOAD_TRIP;
            else if (low_credit)
                next_state = S_LOW_CREDIT;
        end

        //------------------------------------------------
        S_LOW_CREDIT:
        begin
            if (tamper_detected)
                next_state = S_TAMPER;
            else if (overload)
                next_state = S_OVERLOAD_TRIP;
            else if (pay_received)
                next_state = S_NORMAL;
            else if (low_credit_counter >= LOW_CREDIT_TIMEOUT)
                next_state = S_DISCONNECTED;
        end

        //------------------------------------------------
        S_DISCONNECTED:
        begin
            if (tamper_detected)
                next_state = S_TAMPER;
            else if (overload)
                next_state = S_OVERLOAD_TRIP;
            else if (pay_received)
                next_state = S_NORMAL;
        end

        //------------------------------------------------
        S_OVERLOAD_TRIP:
        begin
            if (tamper_detected)
                next_state = S_TAMPER;
            else if (!overload && pay_received)
                next_state = S_NORMAL;
        end

        //------------------------------------------------
        S_TAMPER:
        begin
            if (!tamper_detected && pay_received)
                next_state = S_NORMAL;
        end

        default:
            next_state = S_INIT;

        endcase
    end

    //----------------------------------------------------
    // Output Logic (Moore FSM)
    //----------------------------------------------------
    always @(*)
    begin

        relay_on       = 0;
        warning        = 0;
        tamper_alarm   = 0;
        measure_enable = 0;

        case(state)

        S_INIT:
        begin
        end

        S_NORMAL:
        begin
            relay_on       = 1;
            measure_enable = sample_tick;
        end

        S_LOW_CREDIT:
        begin
            relay_on       = 1;
            warning        = 1;
            measure_enable = sample_tick;
        end

        S_DISCONNECTED:
        begin
        end

        S_OVERLOAD_TRIP:
        begin
            warning = 1;
        end

        S_TAMPER:
        begin
            tamper_alarm = 1;
        end

        endcase

    end

    //----------------------------------------------------
    // Debug State
    //----------------------------------------------------
    always @(*)
    begin
        state_dbg = state;
    end

endmodule
