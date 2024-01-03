`default_nettype none

module NES_top
(
    input wire sys_clk,  // 27 Mhz, crystal clock from board
    input wire sys_reset_n,
    input wire button_n,   // 0 when pressed

    output wire led, // 1 to light

	// SPI (From JTAG)
	input  wire TCK,
	input  wire TDI,
//	input  wire TMS,
	output wire TDO,

    output wire       hdmi_clk_p,
    output wire       hdmi_clk_n,
    output wire [2:0] hdmi_data_p,
    output wire [2:0] hdmi_data_n,

    output wire [0:0] O_hpram_ck,
    output wire [0:0] O_hpram_ck_n,
    inout  wire [0:0] IO_hpram_rwds,
    inout  wire [7:0] IO_hpram_dq,
    output wire [0:0] O_hpram_reset_n,
    output wire [0:0] O_hpram_cs_n
);

wire serial_clk, pll_124_locked; // 124.875 MHz

    gowin_pllvr_124875 pll_124875 (
        .clkout(serial_clk), //output clkout
        .lock(pll_124_locked), //output lock
        .reset(~sys_reset_n), //input reset
        .clkin(sys_clk) //input clkin
    );

wire sys_reset_124;

	sys_reset rstu_124 (
		.RSTn(sys_reset_n & pll_124_locked), .CLK(sys_clk), .DOUT(sys_reset_124)
	);

wire pixel_clk; // 24.975 MHz

    gowin_clkdiv_5 clkdiv_5 (
        .clkout(pixel_clk), //output clkout
        .hclkin(serial_clk), //input hclkin
        .resetn(sys_reset_n) //input resetn
    );

wire rgb_vs, rgb_hs, rgb_de;
wire [7:0] rgb_r, rgb_g, rgb_b;

	DVI_TX_Top dvi_tx (
		.I_rst_n       (~sys_reset_124),       // input I_rst_n
		.I_serial_clk  (serial_clk),  // input I_serial_clk
		.I_rgb_clk     (pixel_clk),   // input I_rgb_clk
		.I_rgb_vs      (rgb_vs),      // input I_rgb_vs
		.I_rgb_hs      (rgb_hs),      // input I_rgb_hs
		.I_rgb_de      (rgb_de),      // input I_rgb_de
		.I_rgb_r       (rgb_r),       // input [7:0] I_rgb_r
		.I_rgb_g       (rgb_g),       // input [7:0] I_rgb_g
		.I_rgb_b       (rgb_b),       // input [7:0] I_rgb_b
		.O_tmds_clk_p  (hdmi_clk_p),  // output O_tmds_clk_p
		.O_tmds_clk_n  (hdmi_clk_n),  // output O_tmds_clk_n
		.O_tmds_data_p (hdmi_data_p), // output [2:0] O_tmds_data_p
		.O_tmds_data_n (hdmi_data_n)  // output [2:0] O_tmds_data_n
	);

wire hpram_clk, hpram_clk_p, pll_49_locked;

	gowin_pllvr_4995_p90 pll_4995 (
		.clkout(hpram_clk),        // 49.95 MHZ main clock
		.clkoutp(hpram_clk_p),     // 49.95 MHZ phase shifted (90 degrees)
		.lock(pll_49_locked),
		.reset(sys_reset_124),
		.clkin(pixel_clk)      // 24.975 Mhz clock
	);

wire sys_reset_249;

	sys_reset rstu_24975 (
		.RSTn(~sys_reset_124 & pll_49_locked), .CLK(pixel_clk), .DOUT(sys_reset_249)
	);

wire hpram_read, hpram_write, hpram_busy;
wire [21:0] hpram_adrs;
wire [15:0] hpram_din;
wire [15:0] hpram_dout;

	HpramController #(
		.FREQ(49_950_000),
		.LATENCY(3)
	) mem_ctrl (
		.clk(hpram_clk), .clk_p(hpram_clk_p), .resetn(~sys_reset_249),
		.read(hpram_read), .write(hpram_write), .byte_write(1'b0),
		.addr(hpram_adrs), .din(hpram_din), .dout(hpram_dout), .busy(hpram_busy),
		.O_hpram_ck(O_hpram_ck), .O_hpram_ck_n(O_hpram_ck_n), .IO_hpram_rwds(IO_hpram_rwds),
		.IO_hpram_dq(IO_hpram_dq), .O_hpram_cs_n(O_hpram_cs_n), .O_hpram_reset_n(O_hpram_reset_n)
	);

	core CU (
		.p_reset(sys_reset_249), .m_clock(pixel_clk),
		.BTN(~button_n), .LED(led),
		// JTAG
		.TCK(TCK), .TDI(TDI), .TDO(TDO), //.TMS(TMS),
		// HyperRAM
		.hpram_adrs(hpram_adrs), .hpram_din(hpram_din),
		.hpram_read(hpram_read), .hpram_write(hpram_write),
		.hpram_dout(hpram_dout), .hpram_busy(hpram_busy),
		// DVI
		.DVI_VS(rgb_vs), .DVI_HS(rgb_hs), .DVI_DE(rgb_de),
		.DVI_R(rgb_r), .DVI_G(rgb_g), .DVI_B(rgb_b)
	);

endmodule

`default_nettype wire
