
/* Work RAM & Video RAM */
`include "ram_8x2k.v"
//`include "mem_8x2k.v"

/* PPU Sprite */
`include "ram_8x256.v"

/* PPU Pallet */
`include "ram_8x32.v"

/* APU Delay buffer */
`include "ram_8x512.v"

/* Display */
`include "ram_16x256.v"

/* Cartridge ExRAM */
`include "ram_8x8k.v"

`include "rgb_rom.v"

/* ChrRAM */
`include "ram_8x32k.v"
`include "ram_8x256k.v"
