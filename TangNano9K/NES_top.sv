`default_nettype none

module NES_top
(
	input wire sys_clk,  // 27 Mhz, crystal clock from board
	input wire sys_reset_n,
	input wire button_n, // 0 when pressed

	output wire [5:0] LED_n, // 0 to light

	output wire SD_CSn,
	output wire SD_CLK,
	output wire SD_CMD,
	input  wire SD_DAT,

	input  wire UART_rx,
	output wire UART_tx,

	output wire [1:0] O_psram_ck, // Magic ports for PSRAM to be inferred
	output wire [1:0] O_psram_ck_n,
	inout  wire [1:0] IO_psram_rwds,
	inout  wire [15:0] IO_psram_dq,
	output wire [1:0] O_psram_reset_n,
	output wire [1:0] O_psram_cs_n,

	output wire       tmds_clk_p,
	output wire       tmds_clk_n,
	output wire [2:0] tmds_dat_p,
	output wire [2:0] tmds_dat_n
);

wire serial_clk, pll_124_locked; // 124.875 MHz

	gowin_rpll_124875 pll_124875 (
		.clkout(serial_clk),   // output clkout
		.lock(pll_124_locked), // output lock
		.reset(~sys_reset_n),  // input reset
		.clkin(sys_clk)        // input clkin
	);

wire sys_reset_124;

	sys_reset rstu_124 (
		.RSTn(sys_reset_n & pll_124_locked), .CLK(sys_clk), .DOUT(sys_reset_124)
	);

wire pixel_clk; // 24.975 MHz

	gowin_clkdiv_5 clkdiv_5 (
		.clkout(pixel_clk),  // output clkout
		.hclkin(serial_clk), // input hclkin
		.resetn(sys_reset_n) // input resetn
	);

wire rgb_hs, rgb_vs, rgb_de;
wire [7:0] rgb_r, rgb_g, rgb_b;

reg audio_clk;
wire [15:0] Audio [1:0];
reg [15:0] s_Audio [1:0];
// 24.975MHzから64kHzサイクル(32kHzクロック)を生成
// ピクセルクロックと合わせること
	localparam COUNT_WIDTH = 16;
	wire [COUNT_WIDTH-1:0] add;
	wire [COUNT_WIDTH-1:0] max;
	reg  [COUNT_WIDTH-1:0] count;
	wire [COUNT_WIDTH-1:0] sa;

	assign add = COUNT_WIDTH'('d64);
	assign max = COUNT_WIDTH'('d24975);
	assign sa = count - max;

	always @(posedge pixel_clk or posedge sys_reset_124) begin
		if(sys_reset_124)
			count <= 0;
		else if(sa[COUNT_WIDTH-1]) // count < max
			count <= count + add;
		else begin
			count <= sa + add;
			audio_clk <= ~audio_clk;
			if(audio_clk) s_Audio <= Audio; // 立ち下がりでホールド
		end
	end

	hdmi_tx #(
		.CLOCK_FREQUENCY(24.975),
	//	.SYNC_POLARITY("POSITIVE"),
		.AUDIO_FREQUENCY(32.0),
		.PCMFIFO_DEPTH(7) // 01:音出ない(パルスノイズ),234:無音,56:にちゃ?LUT増える,7:SDPX9Bが1つ増える,891011LUTも増える
	) u_tx (
		.reset      (sys_reset_124),
		.clk        (pixel_clk),
		.clk_x5     (serial_clk),
		.active     (rgb_de),
		.r_data     (rgb_r),
		.g_data     (rgb_g),
		.b_data     (rgb_b),
		.hsync      (rgb_hs),
		.vsync      (rgb_vs),
		.pcm_fs     (audio_clk),
		.pcm_l      ({s_Audio[0], 8'b0}),
		.pcm_r      ({s_Audio[1], 8'b0}),
		.data       (tmds_dat_p),
	//	.data_n     (tmds_dat_n),
		.clock      (tmds_clk_p)
	//	.clock_n    (tmds_clk_n)
	);


// Change PLL and here to choose another speed.
localparam FREQ = 49_950_000;
localparam LATENCY = 3; // ok

wire psram_clk, psram_clk_p, pll_49_locked;

	gowin_rpll_4995_p90 pll_4995 (
		.clkout(psram_clk),    // 49.95 MHZ main clock
		.clkoutp(psram_clk_p), // 49.95 MHZ phase shifted (90 degrees)
		.lock(pll_49_locked),
		.reset(sys_reset_124),
		.clkin(pixel_clk)      // 24.975 Mhz clock
	);

wire sys_reset_249_;

	sys_reset rstu_24975 (
		.RSTn(/*sys_reset_n &*/ ~sys_reset_124 & pll_49_locked), .CLK(pixel_clk), .DOUT(sys_reset_249_)
	);

wire sys_reset_249;

	DQCE dqce_inst (
		.CLKIN(sys_reset_249_), .CE(1'b1), .CLKOUT(sys_reset_249)
	);
//assign sys_reset_249 = sys_reset_249_;

wire psram0_read, psram0_write, psram0_busy;
wire [21:0] psram0_adrs;
wire [7:0] psram0_din;
wire [7:0] psram0_dout;

	PsramController #(
		.FREQ(FREQ),
		.LATENCY(LATENCY)
	) mem_ctrl0 (
		.clk(psram_clk), .clk_p(psram_clk_p), .reset(sys_reset_249),
		.read(psram0_read), .write(psram0_write), .byte_write(1'b1),
		.addr(psram0_adrs), .din(psram0_din), .dout(psram0_dout), .busy(psram0_busy),
		.O_psram_ck(O_psram_ck[0]), .O_psram_ck_n(O_psram_ck_n[0]), .IO_psram_rwds(IO_psram_rwds[0]),
		.O_psram_reset_n(O_psram_reset_n[0]), .IO_psram_dq(IO_psram_dq[7:0]), .O_psram_cs_n(O_psram_cs_n[0])
	);

wire psram1_read, psram1_write, psram1_busy;
wire [21:0] psram1_adrs;
wire [7:0] psram1_din;
wire [7:0] psram1_dout;

	PsramController #(
		.FREQ(FREQ),
		.LATENCY(LATENCY)
	) mem_ctrl1 (
		.clk(psram_clk), .clk_p(psram_clk_p), .reset(sys_reset_249),
		.read(psram1_read), .write(psram1_write), .byte_write(1'b1),
		.addr(psram1_adrs), .din(psram1_din), .dout(psram1_dout), .busy(psram1_busy),
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
		.UART_RX(UART_rx), .UART_TX(UART_tx),
		.DVI_VS(rgb_vs), .DVI_HS(rgb_hs), .DVI_DE(rgb_de),
		.DVI_R(rgb_r), .DVI_G(rgb_g), .DVI_B(rgb_b),
		.Audio_L(Audio[0]), .Audio_R(Audio[1])
	);

	assign LED_n = ~led;

endmodule

`default_nettype wire
