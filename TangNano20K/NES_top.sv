`default_nettype none

module NES_top
(
	input wire sys_clk,  // 27 Mhz, crystal clock from board
	input wire sys_reset,
	input wire button,

	output wire [5:0] LED_n,

	output wire SD_CSn,
	output wire SD_CLK,
	output wire SD_CMD,
	input  wire SD_DAT,

	// SDRAM
	output wire O_sdram_clk,
	output wire O_sdram_cke,
	output wire O_sdram_cs_n,            // chip select
	output wire O_sdram_cas_n,           // columns address select
	output wire O_sdram_ras_n,           // row address select
	output wire O_sdram_wen_n,           // write enable
	inout wire [31:0] IO_sdram_dq,       // 32 bit bidirectional data bus
	output wire [10:0] O_sdram_addr,     // 11 bit multiplexed address bus
	output wire [1:0] O_sdram_ba,        // two banks
	output wire [3:0] O_sdram_dqm,        // 32/4

	output wire       DVI_clk_p,
	output wire       DVI_clk_n,
	output wire [2:0] DVI_dat_p,
	output wire [2:0] DVI_dat_n,

	// Dualshock game controller
	output wire joystick_clk,
	output wire joystick_mosi, // cmd
	input  wire joystick_miso, // data
	output wire joystick_cs,

	//Audio
	output wire HP_BCK,
	output wire HP_WS,
	output wire HP_DIN,
	output wire PA_EN
);

wire serial_clk, pll_124_locked; // 124.875 MHz

	gowin_rpll_124875 pll_124875 (
		.clkout(serial_clk),   // output clkout
		.lock(pll_124_locked), // output lock
		.reset(sys_reset),     // input reset
		.clkin(sys_clk)        // input clkin
	);

wire sys_reset_124;

	sys_reset rstu_124 (
		.RSTn(~sys_reset & pll_124_locked), .CLK(sys_clk), .DOUT(sys_reset_124)
	);

wire pixel_clk; // 24.975 MHz

	gowin_clkdiv_5 clkdiv_5 (
		.clkout(pixel_clk),  // output clkout
		.hclkin(serial_clk), // input hclkin
		.resetn(~sys_reset)  // input resetn
	);

wire rgb_vs, rgb_hs, rgb_de;
wire [7:0] rgb_r, rgb_g, rgb_b;

localparam CLKFRQ = 25000000;//24_975_000だと音が落ちる？25_000_000でも落ちる
//localparam AUDIO_RATE = 48000;
localparam AUDIO_RATE = 32000;
localparam AUDIO_CLK_DELAY = CLKFRQ / AUDIO_RATE / 2;
reg [$clog2(AUDIO_CLK_DELAY)-1:0] audio_divider;
reg audio_clk;
wire [15:0] Audio [1:0];
reg [15:0] s_Audio [1:0];

	always @(posedge pixel_clk) begin
		if(audio_divider != AUDIO_CLK_DELAY - 1)
			audio_divider++;
		else begin
			audio_clk <= ~audio_clk;
			audio_divider <= 0;
			// クロックたち下がりでホールド
			if(audio_clk) s_Audio <= Audio; // これでいい
		end
	end

wire [2:0] tmds;
wire tmds_clock;

	// 640x480 @ 60Hz
	hdmi #(
		.VIDEO_ID_CODE(1), // 640x480
		.VIDEO_REFRESH_RATE(60),//59.94),
		.AUDIO_RATE(AUDIO_RATE),
		.AUDIO_BIT_WIDTH(16),
		.START_X(-383), // 60:-383 59.94:-384
		.START_Y(-24) // 60:-24 59.94:-24
	) hdmi_inst (
		.clk_pixel_x5(serial_clk),
		.clk_pixel(pixel_clk),
		.clk_audio(audio_clk),
		.reset(sys_reset_124),
		.rgb({rgb_r, rgb_g, rgb_b}),
		.audio_sample_word(s_Audio),
		.tmds(tmds),//DVI_tx_dat_p),
		.tmds_clock(tmds_clock)//DVI_tx_clk_p)
	);

	ELVDS_OBUF tmds_bufds [3:0] (
		.I({tmds_clock, tmds}), .O({DVI_clk_p, DVI_dat_p}), .OB({DVI_clk_n, DVI_dat_n})
	);

wire core_clk, sdram_clk_p, pll_49_locked;

	gowin_rpll_4995_p90 pll_4995 (
		.clkout(core_clk),     // 49.95 MHZ main clock
		.clkoutp(sdram_clk_p), // 49.95 MHZ phase shifted (90 degrees)
		.lock(pll_49_locked),
		.reset(sys_reset_124),
		.clkin(pixel_clk)      // 24.975 Mhz clock
	);

wire sys_reset_49_;

	sys_reset rstu_4995 (
		.RSTn(/*sys_reset_n &*/ ~sys_reset_124 & pll_49_locked), .CLK(pixel_clk), .DOUT(sys_reset_49_)
	);

wire sys_reset_49;

	DQCE dqce_inst (
		.CLKIN(sys_reset_49_), .CE(1'b1), .CLKOUT(sys_reset_49)
	);
//assign sys_reset_49 = sys_reset_49_;

wire [5:0] led;

wire [31:0] sdram_Din;
wire sdram_Din_En;

	core CU (
		.p_reset(sys_reset_49), .m_clock(core_clk),
		.BTN(button), .LED(led),
		.SDRAM_Dout(IO_sdram_dq), .SDRAM_ADDR(O_sdram_addr), .SDRAM_BA(O_sdram_ba), .SDRAM_CSn(O_sdram_cs_n),
		.SDRAM_WEn(O_sdram_wen_n), .SDRAM_RASn(O_sdram_ras_n), .SDRAM_CASn(O_sdram_cas_n), .SDRAM_DEn(sdram_Din_En),
		.SDRAM_Din(sdram_Din), .SDRAM_DQM(O_sdram_dqm),
		.SD_CSn(SD_CSn), .SD_CLK(SD_CLK), .SD_CMD(SD_CMD), .SD_DAT(SD_DAT),
		.DVI_VS(rgb_vs), .DVI_HS(rgb_hs), .DVI_DE(rgb_de),
		.DVI_R(rgb_r), .DVI_G(rgb_g), .DVI_B(rgb_b),
		.Audio_L(Audio[0]), .Audio_R(Audio[1]),
		.PAD_SELn(joystick_cs), .PAD_CLK(joystick_clk), .PAD_CMD(joystick_mosi), .PAD_DAT(joystick_miso),
		.HP_BCK(HP_BCK), .HP_WS(HP_WS), .HP_DIN(HP_DIN)
	);

	assign LED_n = ~led;

	assign O_sdram_cke = 1'b1;
	assign O_sdram_clk = sdram_clk_p;
	assign IO_sdram_dq = sdram_Din_En==1'b0 ? sdram_Din : 32'bz;

	assign PA_EN = 1'b1;

endmodule

`default_nettype wire
