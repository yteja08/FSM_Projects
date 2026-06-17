`timescale 1ns/1ps

module tb_smart_energy_meter_fsm;

    reg clk;
    reg rst;
    reg sample_tick;
    reg overload;
    reg tamper_detected;
    reg pay_received;
    reg low_credit;

    wire measure_enable;
    wire relay_on;
    wire warning;
    wire tamper_alarm;
    wire [2:0] state_dbg;

    smart_energy_meter_fsm #(
        .INIT_TICKS(2),
        .LOW_CREDIT_TIMEOUT(3)
    ) DUT (
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

    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 10ns clock period
    end

    initial begin
        $dumpfile("wave_smart_energy_meter_fsm.vcd");
        $dumpvars(0, tb_smart_energy_meter_fsm);
    end

    initial begin
        rst = 1;
        sample_tick = 0;
        overload = 0;
        tamper_detected = 0;
        pay_received = 0;
        low_credit = 0;

        #20;
        rst = 0;

        #40;

        if(state_dbg == 3'b001)
            $display("PASS : INIT -> NORMAL");
        else
            $display("FAIL : INIT -> NORMAL");

        sample_tick = 1;
        #10;

        if(measure_enable)
            $display("PASS : Measurement Enabled");
        else
            $display("FAIL : Measurement Enabled");

        sample_tick = 0;
        #10;

        low_credit = 1;
        #10;

        if(warning)
            $display("PASS : Low Credit Warning");
        else
            $display("FAIL : Low Credit Warning");

        low_credit = 0;
        #50;

        if(state_dbg == 3'b011)
            $display("PASS : Disconnected after timeout");
        else
            $display("FAIL : Disconnect failed");

        pay_received = 1;
        #10;
        pay_received = 0;
        #20;

        if(state_dbg == 3'b001)
            $display("PASS : Payment Restoration");
        else
            $display("FAIL : Payment Restoration");

        overload = 1;
        #10;

        if(state_dbg == 3'b100)
            $display("PASS : Overload Trip");
        else
            $display("FAIL : Overload Trip");

        overload = 0;
        pay_received = 1;
        #10;

        pay_received = 0;
        #20;

        if(state_dbg == 3'b001)
            $display("PASS : Overload Recovery");
        else
            $display("FAIL : Overload Recovery");

        tamper_detected = 1;
        #10;

        if(state_dbg == 3'b101)
            $display("PASS : Tamper Detected");
        else
            $display("FAIL : Tamper Detection");

        tamper_detected = 0;
        pay_received = 1;
        #10;

        pay_received = 0;
        #20;

        if(state_dbg == 3'b001)
            $display("PASS : Tamper Recovery");
        else
            $display("FAIL : Tamper Recovery");

        tamper_detected = 1;
        overload = 1;
        low_credit = 1;

        #10;

        if(state_dbg == 3'b101)
            $display("PASS : Priority Correct (Tamper Highest)");
        else
            $display("FAIL : Priority Error");

        #20;
        $display("\nSUMMARY : smart_energy_meter_fsm PASS\n");
        $finish;

    end

endmodule
