
`default_nettype none

module NES_top
(
// CLK = Clock input
// PLL = PLL Output
// IPU = Internal Pull Up
// EPU = External Pull Up

	// Clock, Reset ports
	input  wire pClk21m,	// CLK : VDP Clock(21.47727MHz) from XTAL
	input  wire pExtClk,	// CLK : Reserved (for multi FPGAs)
	output wire pCpuClk,	// PLL : Clock out. Connected pSltClk
	// MSX cartridge slot ports
	input  wire pSltClk,		// CLK : Clock in. Connected pCpuClk
	input  wire pSltRst_n,		// EPU : RESET from Reset-IC(M519538FP)
	inout  wire pSltSltsl_n,	// -   : Select cartrige 1
	inout  wire pSltSlts2_n,	// -   : Select cartrige 2
	inout  wire pSltIorq_n,		// IPU :
	inout  wire pSltRd_n,		// IPU :
	inout  wire pSltWr_n,		// IPU :
	inout  wire [15:0] pSltAdr,	// -   :
	inout  wire [7:0] pSltDat,	// IPU :
	output wire pSltBdir_n,		// IPU : Bus direction (not used in master mode)

	inout wire pSltCs1_n,	// -   :
	inout wire pSltCs2_n,	// -   :
	inout wire pSltCs12_n,	// -   :
	inout wire pSltRfsh_n,	// IPU :
	inout wire pSltWait_n,	// EPU+IPU :
	inout wire pSltInt_n,	// EPU+IPU :
	inout wire pSltM1_n,	// IPU :
	inout wire pSltMerq_n,	// IPU :

	output wire pSltRsv5,	// -   : Reserved
	output wire pSltRsv16,	// EPU : Reserved
	inout  wire pSltSw1,	// -   : Reserved
	inout  wire pSltSw2,	// -   : Reserved
    // SD-RAM ports
	output wire pMemClk,		// -   : SD-RAM Clock
	output wire pMemCke,		// -   : SD-RAM Clock enable
	output wire pMemCs_n,		// -   : SD-RAM Chip select
	output wire pMemRas_n,		// -   : SD-RAM Row/RAS
	output wire pMemCas_n,		// -   : SD-RAM /CAS
	output wire pMemWe_n,		// -   : SD-RAM /WE
	output wire pMemUdq,		// -   : SD-RAM UDQM
	output wire pMemLdq,		// -   : SD-RAM LDQM
	output wire pMemBa1,		// -   : SD-RAM Bank select address 1
	output wire pMemBa0,		// -   : SD-RAM Bank select address 0
	output wire [12:0] pMemAdr,	// -   : SD-RAM Address
	inout  wire [15:0] pMemDat,	// IPU : SD-RAM Data
    // PS/2 keyboard ports
	input  wire pPs2Clk,	// EPU+IPU :
	input  wire pPs2Dat,	// EPU+IPU :
    // Joystick ports (Port_A, Port_B)
	input  wire [5:0] pJoyA,	// EPU+IPU :
	output wire       pStrA,	// IPU : Joystick Common output
	input  wire [5:0] pJoyB,	// EPU+IPU :
	output wire       pStrB,	// IPU : Joystick Common output
    // SD/MMC slot ports
	output wire pSd_Ck,		// EPU+IPU : pin 5(CLK)
	output wire pSd_Cm,		// EPU+IPU : pin 2(CMD)
	input  wire pSd_Dt0,	// IPU : pin 1(D3), 9(D2), 8(D1), 7(D0)
	input  wire pSd_Dt1,	// SPI : not used
	input  wire pSd_Dt2,	// SPI : not used
	output wire pSd_Dt3,	// SPI : CSn out
    // DIP switch, Lamp ports
	inout  wire [7:0] pDip,		// IPU : DIP Switch 0=ON, 1=OFF
	output wire [7:0] pLed,		// IPU : LED 0=OFF, 1=ON(green)
	output wire       pLedPwr,	// IPU : LED 0=OFF, 1=ON(red) ...Power & SD/MMC access lamp
    // Video, Audio/CMT ports
	inout  wire [5:0] pDac_VR,	// Ladder DAC : RGB_Red / Svideo_C
	inout  wire [5:0] pDac_VG,	// Ladder DAC : RGB_Grn / Svideo_Y
	inout  wire [5:0] pDac_VB,	// Ladder DAC : RGB_Blu / CompositeVideo
	output wire [5:0] pDac_SL,	// Ladder DAC : Sound-L
	inout  wire [5:0] pDac_SR,	// Ladder DAC : Sound-R / CMT
	output wire pVideoHS_n,		// IPU : Csync(RGB15K), HSync(VGA31K)
	output wire pVideoVS_n,		// IPU : Audio(RGB15K), VSync(VGA31K)
	output wire pVideoClk,		// IPU : (Reserved)
	output wire pVideoDat,		// IPU : (Reserved)
    // Reserved ports (USB)
	inout wire pUsbP1,	// EPU :
	inout wire pUsbN1,	// EPU :
	inout wire pUsbP2,	// EPU :
	inout wire pUsbN2,	// EPU :
    // Reserved ports
	input wire pIopRsv14,	// IPU :
	input wire pIopRsv15,	// IPU :
	input wire pIopRsv16,	// IPU :
	input wire pIopRsv17,	// IPU :
	input wire pIopRsv18,	// IPU :
	input wire pIopRsv19,	// IPU :
	input wire pIopRsv20,	// IPU :
	input wire pIopRsv21	// IPU :
);

//====================================================
// wire/regs
//====================================================

wire clk_50MHz, locked;
wire reset, g_reset;

wire [15:0] sdram_Dout;
wire sdram_Dout_En;
wire [1:0] sdram_BA;

//wire sd_cmd_out, sd_cmd_en;

wire sound_L, sound_R;

//====================================================

	main_pll_50MHz main_pll_inst (
		.areset(~pSltRst_n), .inclk0(pClk21m), .c0(clk_50MHz), .c1(pMemClk), .locked(locked)
	);

	sys_reset RSTU (
		.RSTn(locked), .CLK(clk_50MHz), .DOUT(reset)
	);

	GLOBAL rst_GU (
		.IN(reset), .OUT(g_reset)
	);

	core CU (
		.p_reset(g_reset),
		.m_clock(clk_50MHz),
	//	.SW(pDip),
		.LEDP(pLedPwr),
		.LED({pLed[0],pLed[1],pLed[2],pLed[3],pLed[4],pLed[5],pLed[6],pLed[7]}),
//--------------------- SDRAM Interface --------------------
		.SDRAM_CSn(pMemCs_n), .SDRAM_WEn(pMemWe_n), .SDRAM_DEn(sdram_Dout_En),
		.SDRAM_RASn(pMemRas_n), .SDRAM_CASn(pMemCas_n),
		.SDRAM_BA(sdram_BA), .SDRAM_ADDR(pMemAdr),
		.SDRAM_LDQM(pMemLdq), .SDRAM_UDQM(pMemUdq),
		.SDRAM_Din(pMemDat), .SDRAM_Dout(sdram_Dout),
//--------------------- SD_Card Interface ------------------
		.SD_CSn(pSd_Dt3), .SD_CLK(pSd_Ck), // SPI mode
		.SD_CMD(pSd_Cm), .SD_DAT(pSd_Dt0),  // SPI mode
//-------------------- PS/2 --------------------------------
		.PS2_KBCLK(pPs2Clk), .PS2_KBDAT(pPs2Dat),
//--------------------- VGA --------------------------------
		.VGA_HS(pVideoHS_n), .VGA_VS(pVideoVS_n),
		.VGA_R(pDac_VR), .VGA_G(pDac_VG), .VGA_B(pDac_VB),
//--------------------- Sound ------------------------------
		.Sound_Left(sound_L), .Sound_Right(sound_R),
//-------------------- JoyPad ------------------------------
		.JoyA(~pJoyA), .JoyB(~pJoyB)
	);

	// SD-RAM ports
	assign pMemCke = 1'b1;
	assign pMemBa0 = sdram_BA[0];
	assign pMemBa1 = sdram_BA[1];
	assign pMemDat = sdram_Dout_En==1'b0 ? sdram_Dout : 16'hzzzz;

    assign pCpuClk = 1'bz;

    // MSX cartridge slot ports
    assign pSltSltsl_n = 1'bz;
    assign pSltSlts2_n = 1'bz;
    assign pSltIorq_n  = 1'bz;
    assign pSltRd_n    = 1'bz;
    assign pSltWr_n    = 1'bz;
    assign pSltAdr     = 16'hzzzz;
    assign pSltDat     = 8'hzz;
    assign pSltBdir_n  = 1'b0;
    assign pSltCs1_n  = 1'bz;
    assign pSltCs2_n  = 1'bz;
    assign pSltCs12_n = 1'bz;
    assign pSltRfsh_n = 1'bz;
    assign pSltWait_n = 1'bz;
    assign pSltInt_n  = 1'bz;
    assign pSltM1_n   = 1'bz;
    assign pSltMerq_n = 1'bz;
    assign pSltRsv5  = 1'b0;
    assign pSltRsv16 = 1'b0;
    assign pSltSw1   = 1'bz;
    assign pSltSw2   = 1'bz;

    // Joystick ports (Port_A, Port_B)
    assign pStrA = 1'b0;
    assign pStrB = 1'b0;

    // SD/MMC slot ports
    /*
  assign pSd_Dt0 = 1'bz; // SPI mode
    assign pSd_Dt1 = 1'bz; // SPI mode
    assign pSd_Dt2 = 1'bz; // SPI mode
*/

//    assign pLedPwr = 1'b1;

    // Video, Audio/CMT ports
    assign pDac_SL = {sound_L, 5'b00000};
    assign pDac_SR = {sound_R, 5'b00000};

    assign pVideoClk = 1'b1;
    assign pVideoDat = 1'b1;

    // Reserved ports (USB)
    assign pUsbP1 = 1'bz;
    assign pUsbN1 = 1'bz;
    assign pUsbP2 = 1'bz;
    assign pUsbN2 = 1'bz;

endmodule

`default_nettype wire
