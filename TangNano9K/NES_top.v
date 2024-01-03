`default_nettype none

module NES_top
(
    input wire sys_clk,  // 27 Mhz, crystal clock from board
    input wire sys_reset_n,
    input wire button_n,   // 0 when pressed

    output wire [5:0] led_n, // 0 to light

    output wire SD_CSn,
    output wire SD_CLK,
    output wire SD_CMD,
    input  wire SD_DAT,

    output wire [1:0] O_psram_ck,       // Magic ports for PSRAM to be inferred
    output wire [1:0] O_psram_ck_n,
    inout  wire [1:0] IO_psram_rwds,
    inout  wire [15:0] IO_psram_dq,
    output wire [1:0] O_psram_reset_n,
    output wire [1:0] O_psram_cs_n,

    output wire       dvi_tx_clk_p,
    output wire       dvi_tx_clk_n,
    output wire [2:0] dvi_tx_data_p,
    output wire [2:0] dvi_tx_data_n
);

wire serial_clk, pll_124_locked; // 124.875 MHz

    gowin_rpll_124875 pll_124875 (
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
		.O_tmds_clk_p  (dvi_tx_clk_p),  // output O_tmds_clk_p
		.O_tmds_clk_n  (dvi_tx_clk_n),  // output O_tmds_clk_n
		.O_tmds_data_p (dvi_tx_data_p), // output [2:0] O_tmds_data_p
		.O_tmds_data_n (dvi_tx_data_n)  // output [2:0] O_tmds_data_n
	);

// Change PLL and here to choose another speed.
localparam FREQ = 49_950_000;
localparam LATENCY = 3; // ok

wire psram_clk, psram_clk_p, pll_49_locked;

	gowin_rpll_4995_p90 pll_4995 (
		.clkout(psram_clk),        // 49.95 MHZ main clock
		.clkoutp(psram_clk_p),     // 49.95 MHZ phase shifted (90 degrees)
		.lock(pll_49_locked),
		.reset(sys_reset_124),
		.clkin(pixel_clk)      // 24.975 Mhz clock
	);

wire sys_reset_249;

	sys_reset rstu_24975 (
		.RSTn(/*sys_reset_n &*/ ~sys_reset_124 & pll_49_locked), .CLK(pixel_clk), .DOUT(sys_reset_249)
	);

wire psram0_read, psram0_write, psram0_busy;
wire [19:0] psram0_adrs;
wire [15:0] psram0_din;
wire [15:0] psram0_dout;

	PsramController #(
		.FREQ(FREQ),
		.LATENCY(LATENCY)
	) mem_ctrl0 (
		.clk(psram_clk), .clk_p(psram_clk_p), .resetn(~sys_reset_249),
		.read(psram0_read), .write(psram0_write), .byte_write(1'b0),
		.addr({psram0_adrs,1'b0}), .din(psram0_din), .dout(psram0_dout), .busy(psram0_busy),
		.O_psram_ck(O_psram_ck[0]), .O_psram_ck_n(O_psram_ck_n[0]), .IO_psram_rwds(IO_psram_rwds[0]),
		.O_psram_reset_n(O_psram_reset_n[0]), .IO_psram_dq(IO_psram_dq[7:0]), .O_psram_cs_n(O_psram_cs_n[0])
	);

wire psram1_read, psram1_write, psram1_busy;
wire [19:0] psram1_adrs;
wire [15:0] psram1_din;
wire [15:0] psram1_dout;

	PsramController #(
		.FREQ(FREQ),
		.LATENCY(LATENCY)
	) mem_ctrl1 (
		.clk(psram_clk), .clk_p(psram_clk_p), .resetn(~sys_reset_249),
		.read(psram1_read), .write(psram1_write), .byte_write(1'b0),
		.addr({psram1_adrs,1'b0}), .din(psram1_din), .dout(psram1_dout), .busy(psram1_busy),
		.O_psram_ck(O_psram_ck[1]), .O_psram_ck_n(O_psram_ck_n[1]), .IO_psram_rwds(IO_psram_rwds[1]),
		.O_psram_reset_n(O_psram_reset_n[1]), .IO_psram_dq(IO_psram_dq[15:8]), .O_psram_cs_n(O_psram_cs_n[1])
	);

wire [5:0] led;

	core CU (
		.p_reset(sys_reset_249), .m_clock(pixel_clk),
		.BTN(~button_n), .LED(led),
		.psram0_adrs(psram0_adrs), .psram0_din(psram0_din),
		.psram0_read(psram0_read), .psram0_write(psram0_write),
		.psram0_dout(psram0_dout), .psram0_busy(psram0_busy),
		.psram1_adrs(psram1_adrs), .psram1_din(psram1_din),
		.psram1_read(psram1_read), .psram1_write(psram1_write),
		.psram1_dout(psram1_dout), .psram1_busy(psram1_busy),
		.SD_CSn(SD_CSn), .SD_CLK(SD_CLK),
		.SD_CMD(SD_CMD), .SD_DAT(SD_DAT),
		.DVI_VS(rgb_vs), .DVI_HS(rgb_hs), .DVI_DE(rgb_de),
		.DVI_R(rgb_r), .DVI_G(rgb_g), .DVI_B(rgb_b)
	);

	assign led_n = ~led;

endmodule

`default_nettype wire
