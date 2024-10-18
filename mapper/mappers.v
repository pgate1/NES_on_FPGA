
// FDS
`include "fds/mul_6.v"
`include "fds/mul_12.v"
`include "fds/mul_s7.v"
`include "fds/mul_s13.v"
`include "fds/fds_core.v"

// MMC5
`include "mmc5/mmc5_core.v"

// N106
//`include "n106/regs_8x128.v"
`include "n106/mul_4.v"
`include "n106/n106_core.v"

// SN5B
`include "sn5b/sn_tone_gen.v"
`include "sn5b/sn_noise_gen.v"
`include "sn5b/sn_envelope_gen.v"
`include "sn5b/sn5b_core.v"

// VRC6
`include "vrc6/sq_ch.v"
`include "vrc6/saw_ch.v"
`include "vrc6/vrc6_core.v"

// VRC7
`include "vrc7/vrc7_fifo.v"

`include "Mapper000.v"
`include "Mapper001.v"
`include "Mapper002.v"
`include "Mapper003.v"
`include "Mapper004.v"
`include "Mapper005.v"
`include "Mapper010.v"
`include "Mapper016.v"
`include "Mapper019.v"
`include "Mapper023.v"
`include "Mapper025.v"
`include "Mapper069.v"
`include "Mapper073.v"
`include "Mapper080.v"
`include "Mapper089.v"
`include "Mapper118.v"

`include "nsf_init_rom.v"
`include "MapperNSF.v"
`include "MapperNSF_nonEx.v"

`include "MapperDummy.v"
`include "Mapper.v"
