// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.1 (win64) Build 5076996 Wed May 22 18:37:14 MDT 2024
// Date        : Fri Oct 18 01:47:23 2024
// Host        : NickAsusRogSrix running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/nicho/OneDrive/Documents/MIT/Classes/6.205/lab07/ip/fifo/ip/fifo/fifo_stub.v
// Design      : fifo
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7s50csga324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_10,Vivado 2024.1" *)
module fifo(wr_clk, rd_clk, din, wr_en, rd_en, dout, full, empty)
/* synthesis syn_black_box black_box_pad_pin="din[36:0],wr_en,rd_en,dout[36:0],full,empty" */
/* synthesis syn_force_seq_prim="wr_clk" */
/* synthesis syn_force_seq_prim="rd_clk" */;
  input wr_clk /* synthesis syn_isclock = 1 */;
  input rd_clk /* synthesis syn_isclock = 1 */;
  input [36:0]din;
  input wr_en;
  input rd_en;
  output [36:0]dout;
  output full;
  output empty;
endmodule
