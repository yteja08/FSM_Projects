# Clock signal
set_property -dict { PACKAGE_PIN N11    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -name sys_clk -period 10.000 [get_ports clk];
 
# Switches
set_property -dict { PACKAGE_PIN L5    IOSTANDARD LVCMOS33 } [get_ports {sample_tick}];
set_property -dict { PACKAGE_PIN L4    IOSTANDARD LVCMOS33 } [get_ports {overload}];
set_property -dict { PACKAGE_PIN M4    IOSTANDARD LVCMOS33 } [get_ports {tamper_detected}];
set_property -dict { PACKAGE_PIN M2    IOSTANDARD LVCMOS33 } [get_ports {pay_received}];
set_property -dict { PACKAGE_PIN M1    IOSTANDARD LVCMOS33 } [get_ports {low_credit}];

# LEDs
set_property -dict { PACKAGE_PIN J3    IOSTANDARD LVCMOS33 } [get_ports {relay_on}];
set_property -dict { PACKAGE_PIN H3    IOSTANDARD LVCMOS33 } [get_ports {tamper_alarm}];
set_property -dict { PACKAGE_PIN J1    IOSTANDARD LVCMOS33 } [get_ports {measure_enable}];
set_property -dict { PACKAGE_PIN K1    IOSTANDARD LVCMOS33 } [get_ports {state_dbg[0]}];
set_property -dict { PACKAGE_PIN L3    IOSTANDARD LVCMOS33 } [get_ports {state_dbg[1]}];
set_property -dict { PACKAGE_PIN L2    IOSTANDARD LVCMOS33 } [get_ports {state_dbg[2]}];
set_property -dict { PACKAGE_PIN K3    IOSTANDARD LVCMOS33 } [get_ports {warning}];

set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {rst}];