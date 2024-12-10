// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.1 (win64) Build 5076996 Wed May 22 18:37:14 MDT 2024
// Date        : Fri Oct 18 01:47:23 2024
// Host        : NickAsusRogSrix running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               c:/Users/nicho/OneDrive/Documents/MIT/Classes/6.205/lab07/ip/fifo/ip/fifo/fifo_sim_netlist.v
// Design      : fifo
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7s50csga324-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "fifo,fifo_generator_v13_2_10,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "fifo_generator_v13_2_10,Vivado 2024.1" *) 
(* NotValidForBitStream *)
module fifo
   (wr_clk,
    rd_clk,
    din,
    wr_en,
    rd_en,
    dout,
    full,
    empty);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 write_clk CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME write_clk, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0" *) input wr_clk;
  (* x_interface_info = "xilinx.com:signal:clock:1.0 read_clk CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME read_clk, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0" *) input rd_clk;
  (* x_interface_info = "xilinx.com:interface:fifo_write:1.0 FIFO_WRITE WR_DATA" *) input [36:0]din;
  (* x_interface_info = "xilinx.com:interface:fifo_write:1.0 FIFO_WRITE WR_EN" *) input wr_en;
  (* x_interface_info = "xilinx.com:interface:fifo_read:1.0 FIFO_READ RD_EN" *) input rd_en;
  (* x_interface_info = "xilinx.com:interface:fifo_read:1.0 FIFO_READ RD_DATA" *) output [36:0]dout;
  (* x_interface_info = "xilinx.com:interface:fifo_write:1.0 FIFO_WRITE FULL" *) output full;
  (* x_interface_info = "xilinx.com:interface:fifo_read:1.0 FIFO_READ EMPTY" *) output empty;

  wire [36:0]din;
  wire [36:0]dout;
  wire empty;
  wire full;
  wire rd_clk;
  wire rd_en;
  wire wr_clk;
  wire wr_en;
  wire NLW_U0_almost_empty_UNCONNECTED;
  wire NLW_U0_almost_full_UNCONNECTED;
  wire NLW_U0_axi_ar_dbiterr_UNCONNECTED;
  wire NLW_U0_axi_ar_overflow_UNCONNECTED;
  wire NLW_U0_axi_ar_prog_empty_UNCONNECTED;
  wire NLW_U0_axi_ar_prog_full_UNCONNECTED;
  wire NLW_U0_axi_ar_sbiterr_UNCONNECTED;
  wire NLW_U0_axi_ar_underflow_UNCONNECTED;
  wire NLW_U0_axi_aw_dbiterr_UNCONNECTED;
  wire NLW_U0_axi_aw_overflow_UNCONNECTED;
  wire NLW_U0_axi_aw_prog_empty_UNCONNECTED;
  wire NLW_U0_axi_aw_prog_full_UNCONNECTED;
  wire NLW_U0_axi_aw_sbiterr_UNCONNECTED;
  wire NLW_U0_axi_aw_underflow_UNCONNECTED;
  wire NLW_U0_axi_b_dbiterr_UNCONNECTED;
  wire NLW_U0_axi_b_overflow_UNCONNECTED;
  wire NLW_U0_axi_b_prog_empty_UNCONNECTED;
  wire NLW_U0_axi_b_prog_full_UNCONNECTED;
  wire NLW_U0_axi_b_sbiterr_UNCONNECTED;
  wire NLW_U0_axi_b_underflow_UNCONNECTED;
  wire NLW_U0_axi_r_dbiterr_UNCONNECTED;
  wire NLW_U0_axi_r_overflow_UNCONNECTED;
  wire NLW_U0_axi_r_prog_empty_UNCONNECTED;
  wire NLW_U0_axi_r_prog_full_UNCONNECTED;
  wire NLW_U0_axi_r_sbiterr_UNCONNECTED;
  wire NLW_U0_axi_r_underflow_UNCONNECTED;
  wire NLW_U0_axi_w_dbiterr_UNCONNECTED;
  wire NLW_U0_axi_w_overflow_UNCONNECTED;
  wire NLW_U0_axi_w_prog_empty_UNCONNECTED;
  wire NLW_U0_axi_w_prog_full_UNCONNECTED;
  wire NLW_U0_axi_w_sbiterr_UNCONNECTED;
  wire NLW_U0_axi_w_underflow_UNCONNECTED;
  wire NLW_U0_axis_dbiterr_UNCONNECTED;
  wire NLW_U0_axis_overflow_UNCONNECTED;
  wire NLW_U0_axis_prog_empty_UNCONNECTED;
  wire NLW_U0_axis_prog_full_UNCONNECTED;
  wire NLW_U0_axis_sbiterr_UNCONNECTED;
  wire NLW_U0_axis_underflow_UNCONNECTED;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_m_axi_arvalid_UNCONNECTED;
  wire NLW_U0_m_axi_awvalid_UNCONNECTED;
  wire NLW_U0_m_axi_bready_UNCONNECTED;
  wire NLW_U0_m_axi_rready_UNCONNECTED;
  wire NLW_U0_m_axi_wlast_UNCONNECTED;
  wire NLW_U0_m_axi_wvalid_UNCONNECTED;
  wire NLW_U0_m_axis_tlast_UNCONNECTED;
  wire NLW_U0_m_axis_tvalid_UNCONNECTED;
  wire NLW_U0_overflow_UNCONNECTED;
  wire NLW_U0_prog_empty_UNCONNECTED;
  wire NLW_U0_prog_full_UNCONNECTED;
  wire NLW_U0_rd_rst_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_s_axis_tready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire NLW_U0_underflow_UNCONNECTED;
  wire NLW_U0_valid_UNCONNECTED;
  wire NLW_U0_wr_ack_UNCONNECTED;
  wire NLW_U0_wr_rst_busy_UNCONNECTED;
  wire [4:0]NLW_U0_axi_ar_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_ar_rd_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_ar_wr_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_aw_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_aw_rd_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_aw_wr_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_b_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_b_rd_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_b_wr_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_r_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_r_rd_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_r_wr_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_w_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_w_rd_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_w_wr_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axis_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axis_rd_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axis_wr_data_count_UNCONNECTED;
  wire [5:0]NLW_U0_data_count_UNCONNECTED;
  wire [31:0]NLW_U0_m_axi_araddr_UNCONNECTED;
  wire [1:0]NLW_U0_m_axi_arburst_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_arcache_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_arid_UNCONNECTED;
  wire [7:0]NLW_U0_m_axi_arlen_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_arlock_UNCONNECTED;
  wire [2:0]NLW_U0_m_axi_arprot_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_arqos_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_arregion_UNCONNECTED;
  wire [2:0]NLW_U0_m_axi_arsize_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_aruser_UNCONNECTED;
  wire [31:0]NLW_U0_m_axi_awaddr_UNCONNECTED;
  wire [1:0]NLW_U0_m_axi_awburst_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_awcache_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_awid_UNCONNECTED;
  wire [7:0]NLW_U0_m_axi_awlen_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_awlock_UNCONNECTED;
  wire [2:0]NLW_U0_m_axi_awprot_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_awqos_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_awregion_UNCONNECTED;
  wire [2:0]NLW_U0_m_axi_awsize_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_awuser_UNCONNECTED;
  wire [63:0]NLW_U0_m_axi_wdata_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_wid_UNCONNECTED;
  wire [7:0]NLW_U0_m_axi_wstrb_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_wuser_UNCONNECTED;
  wire [7:0]NLW_U0_m_axis_tdata_UNCONNECTED;
  wire [0:0]NLW_U0_m_axis_tdest_UNCONNECTED;
  wire [0:0]NLW_U0_m_axis_tid_UNCONNECTED;
  wire [0:0]NLW_U0_m_axis_tkeep_UNCONNECTED;
  wire [0:0]NLW_U0_m_axis_tstrb_UNCONNECTED;
  wire [3:0]NLW_U0_m_axis_tuser_UNCONNECTED;
  wire [5:0]NLW_U0_rd_data_count_UNCONNECTED;
  wire [0:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [0:0]NLW_U0_s_axi_buser_UNCONNECTED;
  wire [63:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [0:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;
  wire [0:0]NLW_U0_s_axi_ruser_UNCONNECTED;
  wire [5:0]NLW_U0_wr_data_count_UNCONNECTED;

  (* C_ADD_NGC_CONSTRAINT = "0" *) 
  (* C_APPLICATION_TYPE_AXIS = "0" *) 
  (* C_APPLICATION_TYPE_RACH = "0" *) 
  (* C_APPLICATION_TYPE_RDCH = "0" *) 
  (* C_APPLICATION_TYPE_WACH = "0" *) 
  (* C_APPLICATION_TYPE_WDCH = "0" *) 
  (* C_APPLICATION_TYPE_WRCH = "0" *) 
  (* C_AXIS_TDATA_WIDTH = "8" *) 
  (* C_AXIS_TDEST_WIDTH = "1" *) 
  (* C_AXIS_TID_WIDTH = "1" *) 
  (* C_AXIS_TKEEP_WIDTH = "1" *) 
  (* C_AXIS_TSTRB_WIDTH = "1" *) 
  (* C_AXIS_TUSER_WIDTH = "4" *) 
  (* C_AXIS_TYPE = "0" *) 
  (* C_AXI_ADDR_WIDTH = "32" *) 
  (* C_AXI_ARUSER_WIDTH = "1" *) 
  (* C_AXI_AWUSER_WIDTH = "1" *) 
  (* C_AXI_BUSER_WIDTH = "1" *) 
  (* C_AXI_DATA_WIDTH = "64" *) 
  (* C_AXI_ID_WIDTH = "1" *) 
  (* C_AXI_LEN_WIDTH = "8" *) 
  (* C_AXI_LOCK_WIDTH = "1" *) 
  (* C_AXI_RUSER_WIDTH = "1" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_AXI_WUSER_WIDTH = "1" *) 
  (* C_COMMON_CLOCK = "0" *) 
  (* C_COUNT_TYPE = "0" *) 
  (* C_DATA_COUNT_WIDTH = "6" *) 
  (* C_DEFAULT_VALUE = "BlankString" *) 
  (* C_DIN_WIDTH = "37" *) 
  (* C_DIN_WIDTH_AXIS = "1" *) 
  (* C_DIN_WIDTH_RACH = "32" *) 
  (* C_DIN_WIDTH_RDCH = "64" *) 
  (* C_DIN_WIDTH_WACH = "1" *) 
  (* C_DIN_WIDTH_WDCH = "64" *) 
  (* C_DIN_WIDTH_WRCH = "2" *) 
  (* C_DOUT_RST_VAL = "0" *) 
  (* C_DOUT_WIDTH = "37" *) 
  (* C_ENABLE_RLOCS = "0" *) 
  (* C_ENABLE_RST_SYNC = "1" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_ERROR_INJECTION_TYPE = "0" *) 
  (* C_ERROR_INJECTION_TYPE_AXIS = "0" *) 
  (* C_ERROR_INJECTION_TYPE_RACH = "0" *) 
  (* C_ERROR_INJECTION_TYPE_RDCH = "0" *) 
  (* C_ERROR_INJECTION_TYPE_WACH = "0" *) 
  (* C_ERROR_INJECTION_TYPE_WDCH = "0" *) 
  (* C_ERROR_INJECTION_TYPE_WRCH = "0" *) 
  (* C_FAMILY = "spartan7" *) 
  (* C_FULL_FLAGS_RST_VAL = "0" *) 
  (* C_HAS_ALMOST_EMPTY = "0" *) 
  (* C_HAS_ALMOST_FULL = "0" *) 
  (* C_HAS_AXIS_TDATA = "1" *) 
  (* C_HAS_AXIS_TDEST = "0" *) 
  (* C_HAS_AXIS_TID = "0" *) 
  (* C_HAS_AXIS_TKEEP = "0" *) 
  (* C_HAS_AXIS_TLAST = "0" *) 
  (* C_HAS_AXIS_TREADY = "1" *) 
  (* C_HAS_AXIS_TSTRB = "0" *) 
  (* C_HAS_AXIS_TUSER = "1" *) 
  (* C_HAS_AXI_ARUSER = "0" *) 
  (* C_HAS_AXI_AWUSER = "0" *) 
  (* C_HAS_AXI_BUSER = "0" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_AXI_RD_CHANNEL = "1" *) 
  (* C_HAS_AXI_RUSER = "0" *) 
  (* C_HAS_AXI_WR_CHANNEL = "1" *) 
  (* C_HAS_AXI_WUSER = "0" *) 
  (* C_HAS_BACKUP = "0" *) 
  (* C_HAS_DATA_COUNT = "0" *) 
  (* C_HAS_DATA_COUNTS_AXIS = "0" *) 
  (* C_HAS_DATA_COUNTS_RACH = "0" *) 
  (* C_HAS_DATA_COUNTS_RDCH = "0" *) 
  (* C_HAS_DATA_COUNTS_WACH = "0" *) 
  (* C_HAS_DATA_COUNTS_WDCH = "0" *) 
  (* C_HAS_DATA_COUNTS_WRCH = "0" *) 
  (* C_HAS_INT_CLK = "0" *) 
  (* C_HAS_MASTER_CE = "0" *) 
  (* C_HAS_MEMINIT_FILE = "0" *) 
  (* C_HAS_OVERFLOW = "0" *) 
  (* C_HAS_PROG_FLAGS_AXIS = "0" *) 
  (* C_HAS_PROG_FLAGS_RACH = "0" *) 
  (* C_HAS_PROG_FLAGS_RDCH = "0" *) 
  (* C_HAS_PROG_FLAGS_WACH = "0" *) 
  (* C_HAS_PROG_FLAGS_WDCH = "0" *) 
  (* C_HAS_PROG_FLAGS_WRCH = "0" *) 
  (* C_HAS_RD_DATA_COUNT = "0" *) 
  (* C_HAS_RD_RST = "0" *) 
  (* C_HAS_RST = "0" *) 
  (* C_HAS_SLAVE_CE = "0" *) 
  (* C_HAS_SRST = "0" *) 
  (* C_HAS_UNDERFLOW = "0" *) 
  (* C_HAS_VALID = "0" *) 
  (* C_HAS_WR_ACK = "0" *) 
  (* C_HAS_WR_DATA_COUNT = "0" *) 
  (* C_HAS_WR_RST = "0" *) 
  (* C_IMPLEMENTATION_TYPE = "2" *) 
  (* C_IMPLEMENTATION_TYPE_AXIS = "1" *) 
  (* C_IMPLEMENTATION_TYPE_RACH = "1" *) 
  (* C_IMPLEMENTATION_TYPE_RDCH = "1" *) 
  (* C_IMPLEMENTATION_TYPE_WACH = "1" *) 
  (* C_IMPLEMENTATION_TYPE_WDCH = "1" *) 
  (* C_IMPLEMENTATION_TYPE_WRCH = "1" *) 
  (* C_INIT_WR_PNTR_VAL = "0" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_MEMORY_TYPE = "1" *) 
  (* C_MIF_FILE_NAME = "BlankString" *) 
  (* C_MSGON_VAL = "1" *) 
  (* C_OPTIMIZATION_MODE = "0" *) 
  (* C_OVERFLOW_LOW = "0" *) 
  (* C_POWER_SAVING_MODE = "0" *) 
  (* C_PRELOAD_LATENCY = "1" *) 
  (* C_PRELOAD_REGS = "0" *) 
  (* C_PRIM_FIFO_TYPE = "512x72" *) 
  (* C_PRIM_FIFO_TYPE_AXIS = "1kx18" *) 
  (* C_PRIM_FIFO_TYPE_RACH = "512x36" *) 
  (* C_PRIM_FIFO_TYPE_RDCH = "1kx36" *) 
  (* C_PRIM_FIFO_TYPE_WACH = "512x36" *) 
  (* C_PRIM_FIFO_TYPE_WDCH = "1kx36" *) 
  (* C_PRIM_FIFO_TYPE_WRCH = "512x36" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL = "2" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_AXIS = "1022" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_RACH = "1022" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_RDCH = "1022" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_WACH = "1022" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_WDCH = "1022" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_WRCH = "1022" *) 
  (* C_PROG_EMPTY_THRESH_NEGATE_VAL = "3" *) 
  (* C_PROG_EMPTY_TYPE = "0" *) 
  (* C_PROG_EMPTY_TYPE_AXIS = "0" *) 
  (* C_PROG_EMPTY_TYPE_RACH = "0" *) 
  (* C_PROG_EMPTY_TYPE_RDCH = "0" *) 
  (* C_PROG_EMPTY_TYPE_WACH = "0" *) 
  (* C_PROG_EMPTY_TYPE_WDCH = "0" *) 
  (* C_PROG_EMPTY_TYPE_WRCH = "0" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL = "61" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_AXIS = "1023" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_RACH = "1023" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_RDCH = "1023" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_WACH = "1023" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_WDCH = "1023" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_WRCH = "1023" *) 
  (* C_PROG_FULL_THRESH_NEGATE_VAL = "60" *) 
  (* C_PROG_FULL_TYPE = "0" *) 
  (* C_PROG_FULL_TYPE_AXIS = "0" *) 
  (* C_PROG_FULL_TYPE_RACH = "0" *) 
  (* C_PROG_FULL_TYPE_RDCH = "0" *) 
  (* C_PROG_FULL_TYPE_WACH = "0" *) 
  (* C_PROG_FULL_TYPE_WDCH = "0" *) 
  (* C_PROG_FULL_TYPE_WRCH = "0" *) 
  (* C_RACH_TYPE = "0" *) 
  (* C_RDCH_TYPE = "0" *) 
  (* C_RD_DATA_COUNT_WIDTH = "6" *) 
  (* C_RD_DEPTH = "64" *) 
  (* C_RD_FREQ = "1" *) 
  (* C_RD_PNTR_WIDTH = "6" *) 
  (* C_REG_SLICE_MODE_AXIS = "0" *) 
  (* C_REG_SLICE_MODE_RACH = "0" *) 
  (* C_REG_SLICE_MODE_RDCH = "0" *) 
  (* C_REG_SLICE_MODE_WACH = "0" *) 
  (* C_REG_SLICE_MODE_WDCH = "0" *) 
  (* C_REG_SLICE_MODE_WRCH = "0" *) 
  (* C_SELECT_XPM = "0" *) 
  (* C_SYNCHRONIZER_STAGE = "2" *) 
  (* C_UNDERFLOW_LOW = "0" *) 
  (* C_USE_COMMON_OVERFLOW = "0" *) 
  (* C_USE_COMMON_UNDERFLOW = "0" *) 
  (* C_USE_DEFAULT_SETTINGS = "0" *) 
  (* C_USE_DOUT_RST = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_ECC_AXIS = "0" *) 
  (* C_USE_ECC_RACH = "0" *) 
  (* C_USE_ECC_RDCH = "0" *) 
  (* C_USE_ECC_WACH = "0" *) 
  (* C_USE_ECC_WDCH = "0" *) 
  (* C_USE_ECC_WRCH = "0" *) 
  (* C_USE_EMBEDDED_REG = "0" *) 
  (* C_USE_FIFO16_FLAGS = "0" *) 
  (* C_USE_FWFT_DATA_COUNT = "0" *) 
  (* C_USE_PIPELINE_REG = "0" *) 
  (* C_VALID_LOW = "0" *) 
  (* C_WACH_TYPE = "0" *) 
  (* C_WDCH_TYPE = "0" *) 
  (* C_WRCH_TYPE = "0" *) 
  (* C_WR_ACK_LOW = "0" *) 
  (* C_WR_DATA_COUNT_WIDTH = "6" *) 
  (* C_WR_DEPTH = "64" *) 
  (* C_WR_DEPTH_AXIS = "1024" *) 
  (* C_WR_DEPTH_RACH = "16" *) 
  (* C_WR_DEPTH_RDCH = "1024" *) 
  (* C_WR_DEPTH_WACH = "16" *) 
  (* C_WR_DEPTH_WDCH = "1024" *) 
  (* C_WR_DEPTH_WRCH = "16" *) 
  (* C_WR_FREQ = "1" *) 
  (* C_WR_PNTR_WIDTH = "6" *) 
  (* C_WR_PNTR_WIDTH_AXIS = "10" *) 
  (* C_WR_PNTR_WIDTH_RACH = "4" *) 
  (* C_WR_PNTR_WIDTH_RDCH = "10" *) 
  (* C_WR_PNTR_WIDTH_WACH = "4" *) 
  (* C_WR_PNTR_WIDTH_WDCH = "10" *) 
  (* C_WR_PNTR_WIDTH_WRCH = "4" *) 
  (* C_WR_RESPONSE_LATENCY = "1" *) 
  (* is_du_within_envelope = "true" *) 
  fifo_generator_v13_2_10 U0
       (.almost_empty(NLW_U0_almost_empty_UNCONNECTED),
        .almost_full(NLW_U0_almost_full_UNCONNECTED),
        .axi_ar_data_count(NLW_U0_axi_ar_data_count_UNCONNECTED[4:0]),
        .axi_ar_dbiterr(NLW_U0_axi_ar_dbiterr_UNCONNECTED),
        .axi_ar_injectdbiterr(1'b0),
        .axi_ar_injectsbiterr(1'b0),
        .axi_ar_overflow(NLW_U0_axi_ar_overflow_UNCONNECTED),
        .axi_ar_prog_empty(NLW_U0_axi_ar_prog_empty_UNCONNECTED),
        .axi_ar_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_ar_prog_full(NLW_U0_axi_ar_prog_full_UNCONNECTED),
        .axi_ar_prog_full_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_ar_rd_data_count(NLW_U0_axi_ar_rd_data_count_UNCONNECTED[4:0]),
        .axi_ar_sbiterr(NLW_U0_axi_ar_sbiterr_UNCONNECTED),
        .axi_ar_underflow(NLW_U0_axi_ar_underflow_UNCONNECTED),
        .axi_ar_wr_data_count(NLW_U0_axi_ar_wr_data_count_UNCONNECTED[4:0]),
        .axi_aw_data_count(NLW_U0_axi_aw_data_count_UNCONNECTED[4:0]),
        .axi_aw_dbiterr(NLW_U0_axi_aw_dbiterr_UNCONNECTED),
        .axi_aw_injectdbiterr(1'b0),
        .axi_aw_injectsbiterr(1'b0),
        .axi_aw_overflow(NLW_U0_axi_aw_overflow_UNCONNECTED),
        .axi_aw_prog_empty(NLW_U0_axi_aw_prog_empty_UNCONNECTED),
        .axi_aw_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_aw_prog_full(NLW_U0_axi_aw_prog_full_UNCONNECTED),
        .axi_aw_prog_full_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_aw_rd_data_count(NLW_U0_axi_aw_rd_data_count_UNCONNECTED[4:0]),
        .axi_aw_sbiterr(NLW_U0_axi_aw_sbiterr_UNCONNECTED),
        .axi_aw_underflow(NLW_U0_axi_aw_underflow_UNCONNECTED),
        .axi_aw_wr_data_count(NLW_U0_axi_aw_wr_data_count_UNCONNECTED[4:0]),
        .axi_b_data_count(NLW_U0_axi_b_data_count_UNCONNECTED[4:0]),
        .axi_b_dbiterr(NLW_U0_axi_b_dbiterr_UNCONNECTED),
        .axi_b_injectdbiterr(1'b0),
        .axi_b_injectsbiterr(1'b0),
        .axi_b_overflow(NLW_U0_axi_b_overflow_UNCONNECTED),
        .axi_b_prog_empty(NLW_U0_axi_b_prog_empty_UNCONNECTED),
        .axi_b_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_b_prog_full(NLW_U0_axi_b_prog_full_UNCONNECTED),
        .axi_b_prog_full_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_b_rd_data_count(NLW_U0_axi_b_rd_data_count_UNCONNECTED[4:0]),
        .axi_b_sbiterr(NLW_U0_axi_b_sbiterr_UNCONNECTED),
        .axi_b_underflow(NLW_U0_axi_b_underflow_UNCONNECTED),
        .axi_b_wr_data_count(NLW_U0_axi_b_wr_data_count_UNCONNECTED[4:0]),
        .axi_r_data_count(NLW_U0_axi_r_data_count_UNCONNECTED[10:0]),
        .axi_r_dbiterr(NLW_U0_axi_r_dbiterr_UNCONNECTED),
        .axi_r_injectdbiterr(1'b0),
        .axi_r_injectsbiterr(1'b0),
        .axi_r_overflow(NLW_U0_axi_r_overflow_UNCONNECTED),
        .axi_r_prog_empty(NLW_U0_axi_r_prog_empty_UNCONNECTED),
        .axi_r_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axi_r_prog_full(NLW_U0_axi_r_prog_full_UNCONNECTED),
        .axi_r_prog_full_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axi_r_rd_data_count(NLW_U0_axi_r_rd_data_count_UNCONNECTED[10:0]),
        .axi_r_sbiterr(NLW_U0_axi_r_sbiterr_UNCONNECTED),
        .axi_r_underflow(NLW_U0_axi_r_underflow_UNCONNECTED),
        .axi_r_wr_data_count(NLW_U0_axi_r_wr_data_count_UNCONNECTED[10:0]),
        .axi_w_data_count(NLW_U0_axi_w_data_count_UNCONNECTED[10:0]),
        .axi_w_dbiterr(NLW_U0_axi_w_dbiterr_UNCONNECTED),
        .axi_w_injectdbiterr(1'b0),
        .axi_w_injectsbiterr(1'b0),
        .axi_w_overflow(NLW_U0_axi_w_overflow_UNCONNECTED),
        .axi_w_prog_empty(NLW_U0_axi_w_prog_empty_UNCONNECTED),
        .axi_w_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axi_w_prog_full(NLW_U0_axi_w_prog_full_UNCONNECTED),
        .axi_w_prog_full_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axi_w_rd_data_count(NLW_U0_axi_w_rd_data_count_UNCONNECTED[10:0]),
        .axi_w_sbiterr(NLW_U0_axi_w_sbiterr_UNCONNECTED),
        .axi_w_underflow(NLW_U0_axi_w_underflow_UNCONNECTED),
        .axi_w_wr_data_count(NLW_U0_axi_w_wr_data_count_UNCONNECTED[10:0]),
        .axis_data_count(NLW_U0_axis_data_count_UNCONNECTED[10:0]),
        .axis_dbiterr(NLW_U0_axis_dbiterr_UNCONNECTED),
        .axis_injectdbiterr(1'b0),
        .axis_injectsbiterr(1'b0),
        .axis_overflow(NLW_U0_axis_overflow_UNCONNECTED),
        .axis_prog_empty(NLW_U0_axis_prog_empty_UNCONNECTED),
        .axis_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axis_prog_full(NLW_U0_axis_prog_full_UNCONNECTED),
        .axis_prog_full_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axis_rd_data_count(NLW_U0_axis_rd_data_count_UNCONNECTED[10:0]),
        .axis_sbiterr(NLW_U0_axis_sbiterr_UNCONNECTED),
        .axis_underflow(NLW_U0_axis_underflow_UNCONNECTED),
        .axis_wr_data_count(NLW_U0_axis_wr_data_count_UNCONNECTED[10:0]),
        .backup(1'b0),
        .backup_marker(1'b0),
        .clk(1'b0),
        .data_count(NLW_U0_data_count_UNCONNECTED[5:0]),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .din(din),
        .dout(dout),
        .empty(empty),
        .full(full),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .int_clk(1'b0),
        .m_aclk(1'b0),
        .m_aclk_en(1'b0),
        .m_axi_araddr(NLW_U0_m_axi_araddr_UNCONNECTED[31:0]),
        .m_axi_arburst(NLW_U0_m_axi_arburst_UNCONNECTED[1:0]),
        .m_axi_arcache(NLW_U0_m_axi_arcache_UNCONNECTED[3:0]),
        .m_axi_arid(NLW_U0_m_axi_arid_UNCONNECTED[0]),
        .m_axi_arlen(NLW_U0_m_axi_arlen_UNCONNECTED[7:0]),
        .m_axi_arlock(NLW_U0_m_axi_arlock_UNCONNECTED[0]),
        .m_axi_arprot(NLW_U0_m_axi_arprot_UNCONNECTED[2:0]),
        .m_axi_arqos(NLW_U0_m_axi_arqos_UNCONNECTED[3:0]),
        .m_axi_arready(1'b0),
        .m_axi_arregion(NLW_U0_m_axi_arregion_UNCONNECTED[3:0]),
        .m_axi_arsize(NLW_U0_m_axi_arsize_UNCONNECTED[2:0]),
        .m_axi_aruser(NLW_U0_m_axi_aruser_UNCONNECTED[0]),
        .m_axi_arvalid(NLW_U0_m_axi_arvalid_UNCONNECTED),
        .m_axi_awaddr(NLW_U0_m_axi_awaddr_UNCONNECTED[31:0]),
        .m_axi_awburst(NLW_U0_m_axi_awburst_UNCONNECTED[1:0]),
        .m_axi_awcache(NLW_U0_m_axi_awcache_UNCONNECTED[3:0]),
        .m_axi_awid(NLW_U0_m_axi_awid_UNCONNECTED[0]),
        .m_axi_awlen(NLW_U0_m_axi_awlen_UNCONNECTED[7:0]),
        .m_axi_awlock(NLW_U0_m_axi_awlock_UNCONNECTED[0]),
        .m_axi_awprot(NLW_U0_m_axi_awprot_UNCONNECTED[2:0]),
        .m_axi_awqos(NLW_U0_m_axi_awqos_UNCONNECTED[3:0]),
        .m_axi_awready(1'b0),
        .m_axi_awregion(NLW_U0_m_axi_awregion_UNCONNECTED[3:0]),
        .m_axi_awsize(NLW_U0_m_axi_awsize_UNCONNECTED[2:0]),
        .m_axi_awuser(NLW_U0_m_axi_awuser_UNCONNECTED[0]),
        .m_axi_awvalid(NLW_U0_m_axi_awvalid_UNCONNECTED),
        .m_axi_bid(1'b0),
        .m_axi_bready(NLW_U0_m_axi_bready_UNCONNECTED),
        .m_axi_bresp({1'b0,1'b0}),
        .m_axi_buser(1'b0),
        .m_axi_bvalid(1'b0),
        .m_axi_rdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .m_axi_rid(1'b0),
        .m_axi_rlast(1'b0),
        .m_axi_rready(NLW_U0_m_axi_rready_UNCONNECTED),
        .m_axi_rresp({1'b0,1'b0}),
        .m_axi_ruser(1'b0),
        .m_axi_rvalid(1'b0),
        .m_axi_wdata(NLW_U0_m_axi_wdata_UNCONNECTED[63:0]),
        .m_axi_wid(NLW_U0_m_axi_wid_UNCONNECTED[0]),
        .m_axi_wlast(NLW_U0_m_axi_wlast_UNCONNECTED),
        .m_axi_wready(1'b0),
        .m_axi_wstrb(NLW_U0_m_axi_wstrb_UNCONNECTED[7:0]),
        .m_axi_wuser(NLW_U0_m_axi_wuser_UNCONNECTED[0]),
        .m_axi_wvalid(NLW_U0_m_axi_wvalid_UNCONNECTED),
        .m_axis_tdata(NLW_U0_m_axis_tdata_UNCONNECTED[7:0]),
        .m_axis_tdest(NLW_U0_m_axis_tdest_UNCONNECTED[0]),
        .m_axis_tid(NLW_U0_m_axis_tid_UNCONNECTED[0]),
        .m_axis_tkeep(NLW_U0_m_axis_tkeep_UNCONNECTED[0]),
        .m_axis_tlast(NLW_U0_m_axis_tlast_UNCONNECTED),
        .m_axis_tready(1'b0),
        .m_axis_tstrb(NLW_U0_m_axis_tstrb_UNCONNECTED[0]),
        .m_axis_tuser(NLW_U0_m_axis_tuser_UNCONNECTED[3:0]),
        .m_axis_tvalid(NLW_U0_m_axis_tvalid_UNCONNECTED),
        .overflow(NLW_U0_overflow_UNCONNECTED),
        .prog_empty(NLW_U0_prog_empty_UNCONNECTED),
        .prog_empty_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .prog_empty_thresh_assert({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .prog_empty_thresh_negate({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .prog_full(NLW_U0_prog_full_UNCONNECTED),
        .prog_full_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .prog_full_thresh_assert({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .prog_full_thresh_negate({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .rd_clk(rd_clk),
        .rd_data_count(NLW_U0_rd_data_count_UNCONNECTED[5:0]),
        .rd_en(rd_en),
        .rd_rst(1'b0),
        .rd_rst_busy(NLW_U0_rd_rst_busy_UNCONNECTED),
        .rst(1'b0),
        .s_aclk(1'b0),
        .s_aclk_en(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arcache({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arid(1'b0),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlock(1'b0),
        .s_axi_arprot({1'b0,1'b0,1'b0}),
        .s_axi_arqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_aruser(1'b0),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awcache({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awid(1'b0),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlock(1'b0),
        .s_axi_awprot({1'b0,1'b0,1'b0}),
        .s_axi_awqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awuser(1'b0),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_buser(NLW_U0_s_axi_buser_UNCONNECTED[0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[63:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_ruser(NLW_U0_s_axi_ruser_UNCONNECTED[0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wid(1'b0),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wuser(1'b0),
        .s_axi_wvalid(1'b0),
        .s_axis_tdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axis_tdest(1'b0),
        .s_axis_tid(1'b0),
        .s_axis_tkeep(1'b0),
        .s_axis_tlast(1'b0),
        .s_axis_tready(NLW_U0_s_axis_tready_UNCONNECTED),
        .s_axis_tstrb(1'b0),
        .s_axis_tuser({1'b0,1'b0,1'b0,1'b0}),
        .s_axis_tvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .sleep(1'b0),
        .srst(1'b0),
        .underflow(NLW_U0_underflow_UNCONNECTED),
        .valid(NLW_U0_valid_UNCONNECTED),
        .wr_ack(NLW_U0_wr_ack_UNCONNECTED),
        .wr_clk(wr_clk),
        .wr_data_count(NLW_U0_wr_data_count_UNCONNECTED[5:0]),
        .wr_en(wr_en),
        .wr_rst(1'b0),
        .wr_rst_busy(NLW_U0_wr_rst_busy_UNCONNECTED));
endmodule

(* DEST_SYNC_FF = "2" *) (* INIT_SYNC_FF = "0" *) (* ORIG_REF_NAME = "xpm_cdc_gray" *) 
(* REG_OUTPUT = "1" *) (* SIM_ASSERT_CHK = "0" *) (* SIM_LOSSLESS_GRAY_CHK = "0" *) 
(* VERSION = "0" *) (* WIDTH = "6" *) (* XPM_MODULE = "TRUE" *) 
(* is_du_within_envelope = "true" *) (* keep_hierarchy = "true" *) (* xpm_cdc = "GRAY" *) 
module fifoxpm_cdc_gray
   (src_clk,
    src_in_bin,
    dest_clk,
    dest_out_bin);
  input src_clk;
  input [5:0]src_in_bin;
  input dest_clk;
  output [5:0]dest_out_bin;

  wire [5:0]async_path;
  wire [4:0]binval;
  wire dest_clk;
  (* RTL_KEEP = "true" *) (* async_reg = "true" *) (* xpm_cdc = "GRAY" *) wire [5:0]\dest_graysync_ff[0] ;
  (* RTL_KEEP = "true" *) (* async_reg = "true" *) (* xpm_cdc = "GRAY" *) wire [5:0]\dest_graysync_ff[1] ;
  wire [5:0]dest_out_bin;
  wire [4:0]gray_enc;
  wire src_clk;
  wire [5:0]src_in_bin;

  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][0] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[0]),
        .Q(\dest_graysync_ff[0] [0]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][1] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[1]),
        .Q(\dest_graysync_ff[0] [1]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][2] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[2]),
        .Q(\dest_graysync_ff[0] [2]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][3] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[3]),
        .Q(\dest_graysync_ff[0] [3]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][4] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[4]),
        .Q(\dest_graysync_ff[0] [4]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][5] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[5]),
        .Q(\dest_graysync_ff[0] [5]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][0] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [0]),
        .Q(\dest_graysync_ff[1] [0]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][1] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [1]),
        .Q(\dest_graysync_ff[1] [1]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][2] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [2]),
        .Q(\dest_graysync_ff[1] [2]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][3] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [3]),
        .Q(\dest_graysync_ff[1] [3]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][4] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [4]),
        .Q(\dest_graysync_ff[1] [4]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][5] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [5]),
        .Q(\dest_graysync_ff[1] [5]),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h6996966996696996)) 
    \dest_out_bin_ff[0]_i_1 
       (.I0(\dest_graysync_ff[1] [0]),
        .I1(\dest_graysync_ff[1] [2]),
        .I2(\dest_graysync_ff[1] [4]),
        .I3(\dest_graysync_ff[1] [5]),
        .I4(\dest_graysync_ff[1] [3]),
        .I5(\dest_graysync_ff[1] [1]),
        .O(binval[0]));
  LUT5 #(
    .INIT(32'h96696996)) 
    \dest_out_bin_ff[1]_i_1 
       (.I0(\dest_graysync_ff[1] [1]),
        .I1(\dest_graysync_ff[1] [3]),
        .I2(\dest_graysync_ff[1] [5]),
        .I3(\dest_graysync_ff[1] [4]),
        .I4(\dest_graysync_ff[1] [2]),
        .O(binval[1]));
  LUT4 #(
    .INIT(16'h6996)) 
    \dest_out_bin_ff[2]_i_1 
       (.I0(\dest_graysync_ff[1] [2]),
        .I1(\dest_graysync_ff[1] [4]),
        .I2(\dest_graysync_ff[1] [5]),
        .I3(\dest_graysync_ff[1] [3]),
        .O(binval[2]));
  LUT3 #(
    .INIT(8'h96)) 
    \dest_out_bin_ff[3]_i_1 
       (.I0(\dest_graysync_ff[1] [3]),
        .I1(\dest_graysync_ff[1] [5]),
        .I2(\dest_graysync_ff[1] [4]),
        .O(binval[3]));
  LUT2 #(
    .INIT(4'h6)) 
    \dest_out_bin_ff[4]_i_1 
       (.I0(\dest_graysync_ff[1] [4]),
        .I1(\dest_graysync_ff[1] [5]),
        .O(binval[4]));
  FDRE \dest_out_bin_ff_reg[0] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(binval[0]),
        .Q(dest_out_bin[0]),
        .R(1'b0));
  FDRE \dest_out_bin_ff_reg[1] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(binval[1]),
        .Q(dest_out_bin[1]),
        .R(1'b0));
  FDRE \dest_out_bin_ff_reg[2] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(binval[2]),
        .Q(dest_out_bin[2]),
        .R(1'b0));
  FDRE \dest_out_bin_ff_reg[3] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(binval[3]),
        .Q(dest_out_bin[3]),
        .R(1'b0));
  FDRE \dest_out_bin_ff_reg[4] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(binval[4]),
        .Q(dest_out_bin[4]),
        .R(1'b0));
  FDRE \dest_out_bin_ff_reg[5] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[1] [5]),
        .Q(dest_out_bin[5]),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \src_gray_ff[0]_i_1 
       (.I0(src_in_bin[1]),
        .I1(src_in_bin[0]),
        .O(gray_enc[0]));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \src_gray_ff[1]_i_1 
       (.I0(src_in_bin[2]),
        .I1(src_in_bin[1]),
        .O(gray_enc[1]));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \src_gray_ff[2]_i_1 
       (.I0(src_in_bin[3]),
        .I1(src_in_bin[2]),
        .O(gray_enc[2]));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \src_gray_ff[3]_i_1 
       (.I0(src_in_bin[4]),
        .I1(src_in_bin[3]),
        .O(gray_enc[3]));
  LUT2 #(
    .INIT(4'h6)) 
    \src_gray_ff[4]_i_1 
       (.I0(src_in_bin[5]),
        .I1(src_in_bin[4]),
        .O(gray_enc[4]));
  FDRE \src_gray_ff_reg[0] 
       (.C(src_clk),
        .CE(1'b1),
        .D(gray_enc[0]),
        .Q(async_path[0]),
        .R(1'b0));
  FDRE \src_gray_ff_reg[1] 
       (.C(src_clk),
        .CE(1'b1),
        .D(gray_enc[1]),
        .Q(async_path[1]),
        .R(1'b0));
  FDRE \src_gray_ff_reg[2] 
       (.C(src_clk),
        .CE(1'b1),
        .D(gray_enc[2]),
        .Q(async_path[2]),
        .R(1'b0));
  FDRE \src_gray_ff_reg[3] 
       (.C(src_clk),
        .CE(1'b1),
        .D(gray_enc[3]),
        .Q(async_path[3]),
        .R(1'b0));
  FDRE \src_gray_ff_reg[4] 
       (.C(src_clk),
        .CE(1'b1),
        .D(gray_enc[4]),
        .Q(async_path[4]),
        .R(1'b0));
  FDRE \src_gray_ff_reg[5] 
       (.C(src_clk),
        .CE(1'b1),
        .D(src_in_bin[5]),
        .Q(async_path[5]),
        .R(1'b0));
endmodule

(* DEST_SYNC_FF = "2" *) (* INIT_SYNC_FF = "0" *) (* ORIG_REF_NAME = "xpm_cdc_gray" *) 
(* REG_OUTPUT = "1" *) (* SIM_ASSERT_CHK = "0" *) (* SIM_LOSSLESS_GRAY_CHK = "0" *) 
(* VERSION = "0" *) (* WIDTH = "6" *) (* XPM_MODULE = "TRUE" *) 
(* is_du_within_envelope = "true" *) (* keep_hierarchy = "true" *) (* xpm_cdc = "GRAY" *) 
module fifoxpm_cdc_gray__2
   (src_clk,
    src_in_bin,
    dest_clk,
    dest_out_bin);
  input src_clk;
  input [5:0]src_in_bin;
  input dest_clk;
  output [5:0]dest_out_bin;

  wire [5:0]async_path;
  wire [4:0]binval;
  wire dest_clk;
  (* RTL_KEEP = "true" *) (* async_reg = "true" *) (* xpm_cdc = "GRAY" *) wire [5:0]\dest_graysync_ff[0] ;
  (* RTL_KEEP = "true" *) (* async_reg = "true" *) (* xpm_cdc = "GRAY" *) wire [5:0]\dest_graysync_ff[1] ;
  wire [5:0]dest_out_bin;
  wire [4:0]gray_enc;
  wire src_clk;
  wire [5:0]src_in_bin;

  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][0] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[0]),
        .Q(\dest_graysync_ff[0] [0]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][1] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[1]),
        .Q(\dest_graysync_ff[0] [1]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][2] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[2]),
        .Q(\dest_graysync_ff[0] [2]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][3] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[3]),
        .Q(\dest_graysync_ff[0] [3]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][4] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[4]),
        .Q(\dest_graysync_ff[0] [4]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[0][5] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(async_path[5]),
        .Q(\dest_graysync_ff[0] [5]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][0] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [0]),
        .Q(\dest_graysync_ff[1] [0]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][1] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [1]),
        .Q(\dest_graysync_ff[1] [1]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][2] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [2]),
        .Q(\dest_graysync_ff[1] [2]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][3] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [3]),
        .Q(\dest_graysync_ff[1] [3]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][4] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [4]),
        .Q(\dest_graysync_ff[1] [4]),
        .R(1'b0));
  (* ASYNC_REG *) 
  (* KEEP = "true" *) 
  (* XPM_CDC = "GRAY" *) 
  FDRE \dest_graysync_ff_reg[1][5] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[0] [5]),
        .Q(\dest_graysync_ff[1] [5]),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h6996966996696996)) 
    \dest_out_bin_ff[0]_i_1 
       (.I0(\dest_graysync_ff[1] [0]),
        .I1(\dest_graysync_ff[1] [2]),
        .I2(\dest_graysync_ff[1] [4]),
        .I3(\dest_graysync_ff[1] [5]),
        .I4(\dest_graysync_ff[1] [3]),
        .I5(\dest_graysync_ff[1] [1]),
        .O(binval[0]));
  LUT5 #(
    .INIT(32'h96696996)) 
    \dest_out_bin_ff[1]_i_1 
       (.I0(\dest_graysync_ff[1] [1]),
        .I1(\dest_graysync_ff[1] [3]),
        .I2(\dest_graysync_ff[1] [5]),
        .I3(\dest_graysync_ff[1] [4]),
        .I4(\dest_graysync_ff[1] [2]),
        .O(binval[1]));
  LUT4 #(
    .INIT(16'h6996)) 
    \dest_out_bin_ff[2]_i_1 
       (.I0(\dest_graysync_ff[1] [2]),
        .I1(\dest_graysync_ff[1] [4]),
        .I2(\dest_graysync_ff[1] [5]),
        .I3(\dest_graysync_ff[1] [3]),
        .O(binval[2]));
  LUT3 #(
    .INIT(8'h96)) 
    \dest_out_bin_ff[3]_i_1 
       (.I0(\dest_graysync_ff[1] [3]),
        .I1(\dest_graysync_ff[1] [5]),
        .I2(\dest_graysync_ff[1] [4]),
        .O(binval[3]));
  LUT2 #(
    .INIT(4'h6)) 
    \dest_out_bin_ff[4]_i_1 
       (.I0(\dest_graysync_ff[1] [4]),
        .I1(\dest_graysync_ff[1] [5]),
        .O(binval[4]));
  FDRE \dest_out_bin_ff_reg[0] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(binval[0]),
        .Q(dest_out_bin[0]),
        .R(1'b0));
  FDRE \dest_out_bin_ff_reg[1] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(binval[1]),
        .Q(dest_out_bin[1]),
        .R(1'b0));
  FDRE \dest_out_bin_ff_reg[2] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(binval[2]),
        .Q(dest_out_bin[2]),
        .R(1'b0));
  FDRE \dest_out_bin_ff_reg[3] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(binval[3]),
        .Q(dest_out_bin[3]),
        .R(1'b0));
  FDRE \dest_out_bin_ff_reg[4] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(binval[4]),
        .Q(dest_out_bin[4]),
        .R(1'b0));
  FDRE \dest_out_bin_ff_reg[5] 
       (.C(dest_clk),
        .CE(1'b1),
        .D(\dest_graysync_ff[1] [5]),
        .Q(dest_out_bin[5]),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \src_gray_ff[0]_i_1 
       (.I0(src_in_bin[1]),
        .I1(src_in_bin[0]),
        .O(gray_enc[0]));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \src_gray_ff[1]_i_1 
       (.I0(src_in_bin[2]),
        .I1(src_in_bin[1]),
        .O(gray_enc[1]));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \src_gray_ff[2]_i_1 
       (.I0(src_in_bin[3]),
        .I1(src_in_bin[2]),
        .O(gray_enc[2]));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \src_gray_ff[3]_i_1 
       (.I0(src_in_bin[4]),
        .I1(src_in_bin[3]),
        .O(gray_enc[3]));
  LUT2 #(
    .INIT(4'h6)) 
    \src_gray_ff[4]_i_1 
       (.I0(src_in_bin[5]),
        .I1(src_in_bin[4]),
        .O(gray_enc[4]));
  FDRE \src_gray_ff_reg[0] 
       (.C(src_clk),
        .CE(1'b1),
        .D(gray_enc[0]),
        .Q(async_path[0]),
        .R(1'b0));
  FDRE \src_gray_ff_reg[1] 
       (.C(src_clk),
        .CE(1'b1),
        .D(gray_enc[1]),
        .Q(async_path[1]),
        .R(1'b0));
  FDRE \src_gray_ff_reg[2] 
       (.C(src_clk),
        .CE(1'b1),
        .D(gray_enc[2]),
        .Q(async_path[2]),
        .R(1'b0));
  FDRE \src_gray_ff_reg[3] 
       (.C(src_clk),
        .CE(1'b1),
        .D(gray_enc[3]),
        .Q(async_path[3]),
        .R(1'b0));
  FDRE \src_gray_ff_reg[4] 
       (.C(src_clk),
        .CE(1'b1),
        .D(gray_enc[4]),
        .Q(async_path[4]),
        .R(1'b0));
  FDRE \src_gray_ff_reg[5] 
       (.C(src_clk),
        .CE(1'b1),
        .D(src_in_bin[5]),
        .Q(async_path[5]),
        .R(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2024.1"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
VRufLWT3xuzTvQKo8VrgeA7TQuqzWEYy/B1VZF2gTA62OnYpyvfz/jYVlv8uQmDxe/ByRttr4gwP
tNck8lOlu04WorDYZXBY99Iv+CD1MRsK+y6klNIUbRWjkWmJ0jF7xfzo5v6+6GlaIHD1nYWB0BGS
XKOLLgkxdDTc9QzwJD4=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
uL+N2Y0N0Nss4UIbL4YgwYw1dJAEJxw9VgIJekBqgLF5Hu0OvgBycKBL3tx4bMFtXLoBUh2ZjpPa
Go57AlryR20NeXp3+hoQeboPP11E649UsEN94qUxaPWE5/ujAWzWT8PMJfk3CAspcIaP3XsDNcxF
vPCbKLRNyWvSzyiofwOXgxNNgLi38SzcrWZtPo/eMELIxeVE3bkV2B7I60W9KI1gXiOj3SjPTDnx
EMAbJCwmbwCkTXljtuzvIRTsGb9QIurgASMwg4IWmb9DS6EbeVgoWu9ePD+YKuN3LcW87KSgmC3y
Mirx3ScsFGRfcOAUOLlOQxU4qqE1ZAjtBAua1w==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
ngggZ4AaOolK7F7zeqf8LCxDCGfbvArfgDzbRvoxE+aIi2H2/ZgHbrcaf1Km1cW+38j2kTOpZ5BU
JUI2G5HZNfsoiLXjFbOMvQQqByNzlhCZjrS3N725Cznvy/nQpUy+kW4iA6DQZKnpdC2s18Suxi5p
XtgDcUzCh62ABICOpz8=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
FzAmLTVxyHRqX0WAddlPopAH/5r3ExgkeVujmhMcJXHbjZ+OKAHOMXTsnwDh03EpZ2Dn+0UPeR9J
JML3A+MQGMuUUzy/4d/lj5rriSnTu0eRK0uK6Gl8vjL08vO3UKb6wGj/w9CP45OWOkbMNgZzJkAl
ulPX0OUqymWYOn3WVAtIlaQ0dmpONV8p6Ixe9p5wlEtvy+7JjUPwaVnKlLjKSAaYD07OqMK+IOEP
5oYs2BscpZ3YKlKVJkoU493L7szHHn2LhSUrMld33nLuWIO6WPdo2u2pTnWXl/J1BzNaK1VaLx4R
H7VhIvgYcSlzCrtbQuNHKFtDPGhXjeA41TS29g==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Oad6Ezs+KRRjlYrAkExu4Kft2T1qNa0HGt8W7O1ByK1ecBs0TGWt/sS3pnt6d6jWuqvsWhrmcGsU
TD7Z+IY65xRZ4IJfgngZD8v540FOGMuFUS31UWxcC7CI6qOo20Q0Irtoxrqm01u5p3tI87ApsE8S
lc2lQ5dh54cGYlRfmo5mYTw6WSHyyVYmoh9npUliD4eNVIKUqnBo1kmYzicnKe8ewFKTEWpjdMeZ
/4YxF/NRZzHTA3GIsnjcgOHia68T/NJJ+zQmoNwxerZWWoacU1EU0IHxET3y4fS/u0Af8OJhkGQf
jI0jGobNLRYYufemCxL6333z0oAno0RiPZlavA==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2023_11", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
LVIUY1x0cEHel3aUfppGw9v6zvpZmh/zrCgsFGWLi8t0vWUC/ikETYOpuFw/0f9L2t8c6tQj/BSQ
wjvzq42gFgtW+CFBjgHAVUBDHhzlv/GKUM/2Vq36bMg9H5f44nJH+7mDDGVPf2PyYZRkAosFPUpA
wRqTC/g2mQ0mMY/gZGQRrs+/VY69Ze9sjoEiEXuwkb/+/VjXgHCxiCzG4cKf0ZiQ+rePhqJqB7FK
IJ+6LHriZD474qtFLq3fOZ9mrqOgN7iBQlc66dO9E0RmZZZsWtQQzZ4q1c2pzvsjDdJyWe0mTlwa
QGVmYElSvL9in5WwDxoKM+2J7vco8OIexLgbJg==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Qf9CPkJTDS6nRjzJ66HoyvpTqtDB4QY3Hy9peOp3xA39ggAvytqhHhiPv35dCRWSCdAyO1u2m+O7
/knms947I+MYTpHHfukyZsBbLho0jRq3cSXe9e6VE+4Dt40wryd91cmi93qmeUxg+vf0F91ug50P
gJ4oGYP71ANEq1UaGqGHgVK0ZsY6jTyc0x25eh+fnXg6vElSbqcptvyGMOBVT/g+gDKIheN40WzZ
Tday7b7o8j+UecVazn9OG8lGmgEQH+ilZfelpEFOBKoEc7YS6kKJ1yiX5nxRMJalTuojq5mhxebk
EsmPJe45gdIAuAmBpw3iLddcx52Arew1xpNY9w==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
H+d/6javaSRU2swARkzTIL8p3itaD4ohPxaTAeOjHpt7R9NIiNpHJvUFWkpZ02WVRAGHIw8Kujz3
6qQbQgKv8nhuS0lDhOHSDBVglvTONFSPjBj6pNY2XB24O4tlMghNicwCBXjxGXS6xET2pHNCj46f
01l0BHXfAtSn5SMPu3KYxDnod+2/TDKoWzzX29rrvh4wvf+eKFGbEVa3/RP2yg+Mp05W5p0KZ1Z3
JvOIxc57qFLARbLg1ToAzgZ8iZXLB5tX2Ez+rVDzW4i9ZvMW40QGIP5F6KCmuWunjVyqcasQ+9V7
oxcmw4sBdn0TYckrmrDvGtKxr+at316tB9uFJzLHWIwjnROKDoFwhcBbXzoqNoU/oBWqorM8JnDS
d/8tvN+7zx+k1OgCrpu5jgCA2E9LIMqL+HO19rub4MD4RjgOufHPDbN2wv6I9bj3Tko+kBZSFxxR
1SnGvhgPAaZJxQLEM+WE8SnVMzJI0RKNctcFv/jmWTYmAdTGIiTDAcmW

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
WXM4aFffz6byfeUnRWfxJR3Sbg31hpZIfhJu9O4aqVdZMRQzhrArOJ75qYkGOgZjI+35a4DA9Ohc
RMh3Tm8A5kh9XM67B45s3+7vF8pYIM5pFlzEQBSQ/OeeAi6GNLI2ACXQl1WutRpQKuwX9iboEsRb
Kc1SU6AOV6yaliF6tUt1LL4x+bC8mqlEHTk6SvN7aiA23tVDcik1QSH66CO3/+J5f88G53DHDqtY
T6w2k7pUziwTnLfirI+XpPgqYp9YYRQEv52Q7wTYJlYnVYrMyludNuTaIE27AkgPAneEkdJlrq9l
eVOgs6ZIO1DEusKG7VzkbM1sS0GnU5Zhuj1Eww==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
KJ2iLB3UgRnxezAEg3KJ/gREzXcLo8pOtacMRsDMsFCSD3vYAdGUKSARO8g71pIGFzJo6PBwogFR
MkJED/0TqwZaleoFaN2ULuSnzZGmf8vT0qKvutBGquDn8MH7T3k3wLxcNdZQLnkqisJCMj8u+71g
xMQRAkhtAQvA2cWb6TDQN6jmfByZuu/AH3X+YZ43XIDG/jymNkwyBWNNx0yzbZouJtOuzzYHhYoC
AAuKR+zfynO91P9hcrXFiExHtCmvb73DA4ICLGiOzEj+C1PMPBX9AHdhnWYy5BbQGsd727Y50yNo
xmTU1vBKL2ewwN4j/Ib2AK/Z7T+d/NunpRbCnA==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
eYDP9MWXRUmO05etuHvoqbEMRNQHmR5nos71kLkRxpycXrdpHxalQmyEdCdbeVoM8lN9qwxKuN0l
yQn00dSYRi3P02ygaVsHqVAsRtz2yRpIRjyGMYD7zKpnNQw476DBmK+/sCD7EH6NxSfzUNnfoURL
uIFC0sHEYpwX6Qt2bT2GdCC0OFvaGwQNimyTFdfeey7cdpg9JmsQRgLEUfRwG1Dk0iu258zTUnT+
31O5RA9OwlgZJpC+LpCvL8XAmGZJ4CCeUf2hnpppoV4KphAV4mCBUkNtUYZSJdF0a5cdHFxnxR5n
nI0ed4USMMiNvLqvP0HQgecfCvYzYx9kk0bmtA==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 92528)
`pragma protect data_block
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
2ESNKogNmn0m9kTfF8QuWP0=
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
