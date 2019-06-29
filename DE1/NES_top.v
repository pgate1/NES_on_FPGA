
// NES on FPGA feat. Altera DE1 Top Module
// Copyright (c) 2004 pgate1.

module NES_top
(
	input wire [1:0] CLK_24, // 24 MHz
	input wire [1:0] CLK_27, // 27 MHz
	input wire CLK_50, // 50 MHz
	input wire CLK_EXT, // External Clock
	input wire [3:0] KEY, // Pushbutton : push'0'
	input wire [9:0] SW, // Toggle Switch : up'1'
	output wire [6:0] HEX0, HEX1, HEX2, HEX3, // Seven Segment Digit : '0'light
	output wire [9:0] LEDR, // LED Red '1'light
	output wire [7:0] LEDG, // LED Green '1'light
	input wire UART_RXD, // UART Receiver
	output wire UART_TXD, // UART Transmitter
//--------------------- SRAM Interface ---------------------
	inout wire [15:0] SRAM_DQ,
	output wire [17:0] SRAM_ADDR,
	output wire SRAM_LBn, SRAM_UBn,
	output wire SRAM_CEn, SRAM_OEn, SRAM_WEn,
//--------------------- SDRAM Interface --------------------
	inout wire [15:0] SDRAM_DQ,
	output wire [1:0] SDRAM_BA,
	output wire [11:0] SDRAM_ADDR,
	output wire SDRAM_LDQM, SDRAM_UDQM,
	output wire SDRAM_CKE,  SDRAM_CLK,
	output wire SDRAM_RASn, SDRAM_CASn,
	output wire SDRAM_CSn,  SDRAM_WEn,
//--------------------- Flash Interface --------------------
	inout wire [7:0] FLASH_DQ,
	output wire [21:0] FLASH_ADDR,
	output wire FLASH_RSTn, FLASH_CEn,
	output wire FLASH_OEn,  FLASH_WEn,
//--------------------- SD_Card Interface ------------------
	output wire SD_CSn, // SD Card CSn
	output wire SD_CLK, // SD Card Clock
	output wire SD_CMD, // SD Card Command & Dout
	input wire SD_DAT,  // SD Card Data
//--------------------- PS2 --------------------------------
	input wire PS2_CLK,	PS2_DAT,
//--------------------- USB JTAG link ----------------------
	input wire TDI,  // CPLD -> FPGA (data in)
	input wire TCK,  // CPLD -> FPGA (clk)
	input wire TCS,  // CPLD -> FPGA (CS)
	output wire TDO, // FPGA -> CPLD (data out)
//--------------------- VGA --------------------------------
	output wire VGA_HS, VGA_VS,
	output wire [3:0] VGA_R, VGA_G, VGA_B,
//--------------------- Audio CODEC ------------------------
	inout wire AUD_ADCLRCK, // ADC LR Clock
	input wire AUD_ADCDAT,  // ADC Data
	inout wire AUD_DACLRCK, // DAC LR Clock
	output wire AUD_DACDAT, // DAC Data
	inout wire AUD_BCLK,    // Bit-Stream Clock
	output wire AUD_XCK,    // Chip Clock
//--------------------- I2C --------------------------------
	output wire I2C_SCLK,
	inout wire I2C_SDAT,
//--------------------- GPIO -------------------------------
	inout wire [35:0] GPIO_0, GPIO_1
);

wire p_reset, g_reset, m_clock;

wire [15:0] sram_Dout;
wire sram_Dout_En;

wire [15:0] sdram_Dout;
wire sdram_Dout_En;

wire g_reset_n, CLK_18_4;
wire audio_RD;
wire [31:0] audio_DATA;
wire [6:0] audio_VOL;
wire audio_SET;

	sys_reset RSTU (
		.RSTn(KEY[0]), .CLK(CLK_50), .DOUT(p_reset)
	);
	
	GLOBAL RSTGU (
		.IN(p_reset), .OUT(g_reset)
	);

	core CU (
		.p_reset(g_reset),
		.m_clock(CLK_50),
		.KEY(KEY), .SW(SW),
		.LEDR(LEDR), .LEDG(LEDG),
		.HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3),
		.UART_RXD(UART_RXD), .UART_TXD(UART_TXD),
//--------------------- SRAM Interface ---------------------
		.SRAM_CEn(SRAM_CEn), .SRAM_OEn(SRAM_OEn), .SRAM_WEn(SRAM_WEn),
		.SRAM_LBn(SRAM_LBn), .SRAM_UBn(SRAM_UBn), .SRAM_DEn(sram_Dout_En),
		.SRAM_ADDR(SRAM_ADDR),
		.SRAM_Din(SRAM_DQ), .SRAM_Dout(sram_Dout),
//--------------------- SDRAM Interface --------------------
		.SDRAM_CSn(SDRAM_CSn), .SDRAM_WEn(SDRAM_WEn), .SDRAM_DEn(sdram_Dout_En),
		.SDRAM_RASn(SDRAM_RASn), .SDRAM_CASn(SDRAM_CASn),
		.SDRAM_BA(SDRAM_BA), .SDRAM_ADDR(SDRAM_ADDR),
		.SDRAM_LDQM(SDRAM_LDQM), .SDRAM_UDQM(SDRAM_UDQM),
		.SDRAM_Din(SDRAM_DQ), .SDRAM_Dout(sdram_Dout),
//--------------------- Flash Interface --------------------
//		.FLASH_RSTn(FLASH_RSTn), .FLASH_CEn(FLASH_CEn),
//		.FLASH_OEn(FLASH_OEn), .FLASH_WEn(FLASH_WEn),
//		.FLASH_ADDR(FLASH_ADDR), .FLASH_Din(FLASH_DQ),
//--------------------- SD_Card Interface ------------------
		.SD_CSn(SD_CSn), .SD_CLK(SD_CLK),
		.SD_CMD(SD_CMD), .SD_DAT(SD_DAT),
//--------------------- VGA --------------------------------
		.VGA_HS(VGA_HS), .VGA_VS(VGA_VS),
		.VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
//--------------------- Audio ------------------------
		.audio_RD(audio_RD), .audio_DATA(audio_DATA),
//		.audio_SET(audio_SET), .audio_VOL(audio_VOL),
//--------------------- PS PAD ------------------------
/*
		.PAD_SEL1n(GPIO_1[14]), .PAD_SEL2n(GPIO_1[0]),
		.PAD_CLK(GPIO_1[2]), .PAD_CMD(GPIO_1[8]),
		.PAD_ACKn(GPIO_1[4]), .PAD_DAT(GPIO_1[6])
*/
/*
--		PAD_SEL1n => GPIO_1(15), PAD_SEL2n => GPIO_1(1),
--		PAD_CLK => GPIO_1(3), PAD_CMD => GPIO_1(9),
--		PAD_ACKn => GPIO_1(5), PAD_DAT => GPIO_1(7)
*/
	);

// not used config
//	assign UART_TXD = 1'b1;

	assign SRAM_DQ = sram_Dout_En==1'b0 ? sram_Dout : 16'hzzzz;

	assign SDRAM_CKE = 1'b1;
	sdram_pll sdram_pll_inst (
		.inclk0(CLK_50), .c0(SDRAM_CLK)
	);
	assign SDRAM_DQ = sdram_Dout_En==1'b0 ? sdram_Dout : 16'hzzzz;

	assign g_reset_n = ~g_reset;

	I2C_AV_Config DACConfU (
		.iCLK(CLK_50), .iRST_N(g_reset_n),
		.iVOL(7'b1110111), .iSET(1'b0),
		.I2C_SCLK(I2C_SCLK), .I2C_SDAT(I2C_SDAT)
	);

	// make 18.4MHz
	audio_pll audio_pll_inst (
		.areset(g_reset), .inclk0(CLK_27[0]), .c0(CLK_18_4)
	);

	AUDIO_ctrl AU (
		.iRST_N(g_reset_n), .iCLK_18_4(CLK_18_4),
		.iDATA_RD(audio_RD), .iDATA(audio_DATA),
		.oAUD_BCK(AUD_BCLK), .oAUD_DATA(AUD_DACDAT),
		.oAUD_LRCK(AUD_DACLRCK), .oAUD_XCK(AUD_XCK)
	);

	assign FLASH_DQ = 8'hzz;
// FlashÉÅÉÇÉäñ¢égópê›íË
	assign FLASH_ADDR = 22'b0;
	assign FLASH_RSTn = 1'b1;
	assign FLASH_CEn = 1'b1;
	assign FLASH_OEn = 1'b1;
	assign FLASH_WEn = 1'b1;

	assign GPIO_0 = 36'hz;

	assign GPIO_1[1] = 1'bz;
	assign GPIO_1[3] = 1'bz;
	assign GPIO_1[5] = 1'bz;
	assign GPIO_1[7] = 1'bz;
	assign GPIO_1[9] = 1'bz;
	assign GPIO_1[10] = 1'bz;
	assign GPIO_1[11] = 1'bz;
	assign GPIO_1[12] = 1'b1; // PAD 3.3V
	assign GPIO_1[13] = 1'bz;
	assign GPIO_1[35:15] = 21'bz;

endmodule
