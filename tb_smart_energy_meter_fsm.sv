`timescale 1ns/1ps

module tb_smart_energy_meter_fsm;

    //---------------------------------------
    // DUT Inputs
    //---------------------------------------
    reg clk;
    reg rst;

    reg sample_tick;
    reg overload;
    reg tamper_detected;
    reg pay_received;
    reg low_credit;

    //---------------------------------------
    // DUT Outputs
    //---------------------------------------
    wire measure_enable;
    wire relay_on;
    wire warning;
    wire tamper_alarm;
    wire [2:0] state_dbg;

    //---------------------------------------
    // Instantiate DUT
    //---------------------------------------
    smart_energy_meter_fsm
    #(
        .INIT_TICKS(2),
        .LOW_CREDIT_TIMEOUT(3)
    )
    dut
    (
        .clk(clk),
        .rst(rst),
        .sample_tick(sample_tick),
        .overload(overload),
        .tamper_detected(tamper_detected),
        .pay_received(pay_received),
        .low_credit(low_credit),

        .measure_enable(measure_enable),
        .relay_on(relay_on),
        .warning(warning),
        .tamper_alarm(tamper_alarm),
        .state_dbg(state_dbg)
    );

    //---------------------------------------
    // State Encodings
    //---------------------------------------
    localparam S_INIT          = 3'd0;
    localparam S_NORMAL        = 3'd1;
    localparam S_LOW_CREDIT    = 3'd2;
    localparam S_DISCONNECTED  = 3'd3;
    localparam S_OVERLOAD_TRIP = 3'd4;
    localparam S_TAMPER        = 3'd5;

    //---------------------------------------
    // PASS Counter
    //---------------------------------------
    integer pass_count = 0;

    //---------------------------------------
    // Clock Generation
    //---------------------------------------
    always #5 clk = ~clk;

    //---------------------------------------
    // Task : Check
    //---------------------------------------
    task check;
        input condition;
        input [200*8:1] message;
        begin
            if(condition)
            begin
                pass_count = pass_count + 1;
                $display("[PASS] %s",message);
            end
            else
            begin
                $display("[FAIL] %s",message);
            end
        end
    endtask

    //---------------------------------------
    // Stimulus
    //---------------------------------------
    initial
    begin

        $dumpfile("wave_smart_energy_meter_fsm.vcd");
        $dumpvars(0,tb_smart_energy_meter_fsm);

        clk = 0;

        rst = 0;
        sample_tick = 0;
        overload = 0;
        tamper_detected = 0;
        pay_received = 0;
        low_credit = 0;

        //-----------------------------------
        // RESET
        //-----------------------------------
        @(posedge clk);
        rst = 1;

        @(posedge clk);
        rst = 0;

        check(state_dbg == S_INIT,
              "Reset enters INIT");

        //-----------------------------------
        // INIT -> NORMAL
        //-----------------------------------
        repeat(3) @(posedge clk);

        check(state_dbg == S_NORMAL,
              "INIT completes to NORMAL");

        //-----------------------------------
        // SAMPLE TICK
        //-----------------------------------
        sample_tick = 1;
        #1;

        check(measure_enable == 1,
              "Measurement enabled on sample tick");

        sample_tick = 0;

        //-----------------------------------
        // LOW CREDIT
        //-----------------------------------
        low_credit = 1;

        @(posedge clk);

        check(state_dbg == S_LOW_CREDIT,
              "Entered LOW_CREDIT");

        check(warning == 1,
              "Warning asserted in LOW_CREDIT");

        //-----------------------------------
        // TIMEOUT TO DISCONNECT
        //-----------------------------------
        low_credit = 0;

        repeat(4) @(posedge clk);

        check(state_dbg == S_DISCONNECTED,
              "LOW_CREDIT timeout disconnect");

        //-----------------------------------
        // PAYMENT RESTORE
        //-----------------------------------
        pay_received = 1;

        @(posedge clk);

        check(state_dbg == S_NORMAL,
              "Payment restores NORMAL");

        pay_received = 0;

        //-----------------------------------
        // OVERLOAD
        //-----------------------------------
        overload = 1;

        @(posedge clk);

        check(state_dbg == S_OVERLOAD_TRIP,
              "Overload enters OVERLOAD_TRIP");

        check(warning == 1,
              "Warning asserted in OVERLOAD_TRIP");

        //-----------------------------------
        // OVERLOAD RESTORE
        //-----------------------------------
        overload = 0;
        pay_received = 1;

        @(posedge clk);

        check(state_dbg == S_NORMAL,
              "Overload cleared and payment restores");

        pay_received = 0;

        //-----------------------------------
        // TAMPER
        //-----------------------------------
        tamper_detected = 1;

        @(posedge clk);

        check(state_dbg == S_TAMPER,
              "Tamper enters TAMPER state");

        check(tamper_alarm == 1,
              "Tamper alarm asserted");

        //-----------------------------------
        // TAMPER RESTORE
        //-----------------------------------
        tamper_detected = 0;
        pay_received = 1;

        @(posedge clk);

        check(state_dbg == S_NORMAL,
              "Tamper clear and payment restore");

        pay_received = 0;

        //-----------------------------------
        // PRIORITY TEST
        //-----------------------------------
        low_credit = 1;
        overload = 1;
        tamper_detected = 1;

        @(posedge clk);

        check(state_dbg == S_TAMPER,
              "Tamper has highest priority");

        low_credit = 0;
        overload = 0;
        tamper_detected = 0;

        //-----------------------------------
        // FINAL SUMMARY
        //-----------------------------------
        $display("==================================");
        $display("SUMMARY: smart_energy_meter_fsm PASS (%0d checks)",pass_count);
        $display("==================================");

        #20;
        $finish;

    end

endmodule
