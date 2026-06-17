module smart_energy_meter_fsm#(parameter INIT_TICKS= 2,parameter LOW_CREDIT_TIMEOUT=3)
(
	input  wire clk, rst, sample_tick, overload, tamper_detected, pay_received, low_credit,
	output reg  measure_enable,  relay_on, warning, tamper_alarm,
        output reg [2:0] state_dbg
);

    localparam S_INIT          = 3'd0;
    localparam S_NORMAL        = 3'd1;
    localparam S_LOW_CREDIT    = 3'd2;
    localparam S_DISCONNECTED  = 3'd3;
    localparam S_OVERLOAD_TRIP = 3'd4;
    localparam S_TAMPER        = 3'd5;

    reg [2:0] state;
    reg [2:0] next_state;

    reg [3:0] timer;

    always @(posedge clk)
    begin
        if(rst)
            state <= S_INIT;
        else
            state <= next_state;
    end

    always @(posedge clk)
    begin
        if(rst)
            init_cnt <= 0;
        else if(state == S_INIT)
        begin
            if(init_cnt < INIT_TICKS)
                init_cnt <= init_cnt + 1;
        end
        else
            init_cnt <= 0;
    end

    always @(posedge clk)
    begin
        if(rst)
            low_credit_cnt <= 0;

        else if(state == S_LOW_CREDIT)
        begin
            if(low_credit_cnt < LOW_CREDIT_TIMEOUT)
                low_credit_cnt <= low_credit_cnt + 1;
        end
        else
            low_credit_cnt <= 0;
    end

    always @(*)
    begin
        next_state = state;

        case(state)

            S_INIT:
            begin
                if(init_cnt >= INIT_TICKS)
                    next_state = S_NORMAL;
            end

            S_NORMAL:
            begin
                if(tamper_detected)
                    next_state = S_TAMPER;

                else if(overload)
                    next_state = S_OVERLOAD_TRIP;

                else if(low_credit)
                    next_state = S_LOW_CREDIT;
            end

            S_LOW_CREDIT:
            begin
                if(tamper_detected)
                    next_state = S_TAMPER;

                else if(overload)
                    next_state = S_OVERLOAD_TRIP;

                else if(pay_received)
                    next_state = S_NORMAL;

                else if(low_credit_cnt >= LOW_CREDIT_TIMEOUT)
                    next_state = S_DISCONNECTED;
            end

            S_DISCONNECTED:
            begin
                if(pay_received)
                    next_state = S_NORMAL;
            end

            S_OVERLOAD_TRIP:
            begin
                if((!overload) && pay_received)
                    next_state = S_NORMAL;
            end

            S_TAMPER:
            begin
                if((!tamper_detected) && pay_received)
                    next_state = S_NORMAL;
            end

            default:
                next_state = S_INIT;

        endcase
    end

    always @(*)
    begin
        relay_on       = 0;
        warning        = 0;
        tamper_alarm   = 0;

        case(state)

            S_NORMAL:
                relay_on = 1;

            S_LOW_CREDIT:
            begin
                relay_on = 1;
                warning  = 1;
            end

            S_OVERLOAD_TRIP:
                warning = 1;

            S_TAMPER:
                tamper_alarm = 1;

            default:
                ;
        endcase

        measure_enable = relay_on & sample_tick;

        state_dbg = state;
    end

endmodule

