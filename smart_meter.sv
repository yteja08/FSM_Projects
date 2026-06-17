module smart_energy_meter_fsm #(
    parameter INIT_TICKS = 2,
    parameter LOW_CREDIT_TIMEOUT = 3
)
(
    input  clk,
    input  rst,
    input  sample_tick,
    input  overload,
    input  tamper_detected,
    input  pay_received,
    input  low_credit,

    output reg measure_enable,
    output reg relay_on,
    output reg warning,
    output reg tamper_alarm,
    output reg [2:0] state_dbg
);

 
    parameter S_INIT          = 3'b000;
    parameter S_NORMAL        = 3'b001;
    parameter S_LOW_CREDIT    = 3'b010;
    parameter S_DISCONNECTED  = 3'b011;
    parameter S_OVERLOAD_TRIP = 3'b100;
    parameter S_TAMPER        = 3'b101;

    reg [2:0] state, next_state;


    reg [3:0] timer;

  
    always @(posedge clk) begin
        if (rst)
            state <= S_INIT;
        else
            state <= next_state;
    end


    always @(posedge clk) begin
        if (rst)
            timer <= 0;

        else begin

            case(state)

                S_INIT:
                    if (timer < INIT_TICKS)
                        timer <= timer + 1;
                    else
                        timer <= 0;

                S_LOW_CREDIT:
                    if (timer < LOW_CREDIT_TIMEOUT)
                        timer <= timer + 1;
                    else
                        timer <= 0;

                default:
                    timer <= 0;

            endcase

        end
    end

    always @(*) begin

        next_state = state;

        case(state)


            S_INIT: begin
                if (timer >= INIT_TICKS)
                    next_state = S_NORMAL;
            end


            S_NORMAL: begin
		    if (tamper_detected)
                    next_state = S_TAMPER;
                else if (overload)
                    next_state = S_OVERLOAD_TRIP;

                else if (low_credit)
                    next_state = S_LOW_CREDIT;

            end

            S_LOW_CREDIT: begin

                if (tamper_detected)
                    next_state = S_TAMPER;

                else if (overload)
                    next_state = S_OVERLOAD_TRIP;

                else if (pay_received)
                    next_state = S_NORMAL;

                else if (timer >= LOW_CREDIT_TIMEOUT)
                    next_state = S_DISCONNECTED;

            end

            S_DISCONNECTED: begin
                if (pay_received)
                    next_state = S_NORMAL;
            end

            S_OVERLOAD_TRIP: begin
                if (!overload && pay_received)
                    next_state = S_NORMAL;
            end

            S_TAMPER: begin
                if (!tamper_detected && pay_received)
                    next_state = S_NORMAL;
            end

            default:
                next_state = S_INIT;

        endcase

    end

    always @(*) begin

        relay_on       = 0;
        measure_enable = 0;
        warning        = 0;
        tamper_alarm   = 0;

        case(state)

            S_NORMAL: begin
                relay_on       = 1;
                measure_enable = sample_tick;
            end

            S_LOW_CREDIT: begin
                relay_on       = 1;
                warning        = 1;
                measure_enable = sample_tick;
            end

            S_OVERLOAD_TRIP: begin
                warning = 1;
            end

            S_TAMPER: begin
                tamper_alarm = 1;
            end

        endcase

    end

    always @(*) begin
        state_dbg = state;
    end

endmodule
