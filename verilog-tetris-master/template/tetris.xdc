set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN G19 [get_ports {vgaRed[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[0]}]
set_property PACKAGE_PIN H19 [get_ports {vgaRed[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[1]}]
set_property PACKAGE_PIN J19 [get_ports {vgaRed[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[2]}]
set_property PACKAGE_PIN N19 [get_ports {vgaRed[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[3]}]
set_property PACKAGE_PIN N18 [get_ports {vgaBlue[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[0]}]
set_property PACKAGE_PIN L18 [get_ports {vgaBlue[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[1]}]
set_property PACKAGE_PIN K18 [get_ports {vgaBlue[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[2]}]
set_property PACKAGE_PIN J18 [get_ports {vgaBlue[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[3]}]
set_property PACKAGE_PIN J17 [get_ports {vgaGreen[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[0]}]
set_property PACKAGE_PIN H17 [get_ports {vgaGreen[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[1]}]
set_property PACKAGE_PIN G17 [get_ports {vgaGreen[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[2]}]
set_property PACKAGE_PIN D17 [get_ports {vgaGreen[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports btn_down]
set_property IOSTANDARD LVCMOS33 [get_ports btn_drop]
set_property IOSTANDARD LVCMOS33 [get_ports btn_left]
set_property IOSTANDARD LVCMOS33 [get_ports btn_right]
set_property IOSTANDARD LVCMOS33 [get_ports btn_rotate]
set_property IOSTANDARD LVCMOS33 [get_ports clk_too_fast]
set_property IOSTANDARD LVCMOS33 [get_ports hsync]
set_property IOSTANDARD LVCMOS33 [get_ports sw_pause]
set_property IOSTANDARD LVCMOS33 [get_ports sw_rst]
set_property IOSTANDARD LVCMOS33 [get_ports vsync]
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property PACKAGE_PIN G19 [get_ports {rgb[0]}]
set_property PACKAGE_PIN H19 [get_ports {rgb[1]}]
set_property PACKAGE_PIN J19 [get_ports {rgb[2]}]
set_property PACKAGE_PIN N19 [get_ports {rgb[3]}]
set_property PACKAGE_PIN N18 [get_ports {rgb[4]}]
set_property PACKAGE_PIN L18 [get_ports {rgb[5]}]
set_property PACKAGE_PIN K18 [get_ports {rgb[6]}]
set_property PACKAGE_PIN J18 [get_ports {rgb[7]}]
set_property PACKAGE_PIN J17 [get_ports {rgb[8]}]
set_property PACKAGE_PIN H17 [get_ports {rgb[9]}]
set_property PACKAGE_PIN G17 [get_ports {rgb[10]}]
set_property PACKAGE_PIN D17 [get_ports {rgb[11]}]
set_property PACKAGE_PIN P19 [get_ports hsync]
set_property PACKAGE_PIN R19 [get_ports vsync]
set_property PACKAGE_PIN W19 [get_ports btn_left]
set_property PACKAGE_PIN T17 [get_ports btn_right]
set_property PACKAGE_PIN T18 [get_ports btn_rotate]
set_property PACKAGE_PIN U18 [get_ports btn_drop]
set_property PACKAGE_PIN U17 [get_ports btn_down]
set_property PACKAGE_PIN W5 [get_ports clk_too_fast]
set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property PACKAGE_PIN V17 [get_ports sw_pause]
set_property PACKAGE_PIN V16 [get_ports sw_rst]

set_property PACKAGE_PIN C17 [get_ports PS2_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports PS2_CLK]
set_property PULLUP true [get_ports PS2_CLK]
set_property PACKAGE_PIN B17 [get_ports PS2_DATA]
set_property IOSTANDARD LVCMOS33 [get_ports PS2_DATA]
set_property PULLUP true [get_ports PS2_DATA]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]