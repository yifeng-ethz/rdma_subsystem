// File name: rdma_subsystem_pkg.sv
// Author  : Yifeng Wang (yifenwan@phys.ethz.ch)
// Version : 26.1.0
// Date    : 20260510
// Change  : add shared constants for the RDMA subsystem supercore

`default_nettype none

package rdma_subsystem_pkg;

    localparam int unsigned DMA_DATA_W_DEFAULT_CONST       = 256;
    localparam int unsigned WQE_BUS_W_DEFAULT_CONST        = 512;
    localparam int unsigned AXI_ADDR_W_CONST               = 64;
    localparam int unsigned AXI_ID_W_CONST                 = 4;
    localparam int unsigned AXI_LEN_W_CONST                = 8;
    localparam int unsigned AXI_SIZE_W_CONST               = 3;
    localparam int unsigned AXI_BURST_W_CONST              = 2;
    localparam int unsigned AXIL_ADDR_W_CONST              = 8;
    localparam int unsigned AXIL_DATA_W_CONST              = 32;
    localparam int unsigned AXIL_STRB_W_CONST              = AXIL_DATA_W_CONST / 8;
    localparam int unsigned OPQ_AXIS_DATA_W_CONST          = 36;
    localparam int unsigned OPQ_AXIS_USER_W_CONST          = 2;
    localparam int unsigned SQE_ID_W_CONST                 = 16;
    localparam int unsigned CQE_META_W_CONST               = 64;
    localparam int unsigned DMA_DBG2_META_W_CONST          = 136;
    localparam int unsigned CQ_MSIX_VECTOR_W_CONST         = 5;
    localparam int unsigned VERSION_MAJOR_DEFAULT_CONST    = 26;
    localparam int unsigned VERSION_MINOR_DEFAULT_CONST    = 1;
    localparam int unsigned VERSION_PATCH_DEFAULT_CONST    = 0;
    localparam int unsigned BUILD_DEFAULT_CONST            = 510;
    localparam logic [31:0] VERSION_DATE_DEFAULT_CONST     = 32'd20260510;
    localparam logic [31:0] VERSION_GIT_DEFAULT_CONST      = 32'h0b66_a91b;
    localparam logic [31:0] IP_UID_DEFAULT_CONST           = 32'h4451_4f50;
    localparam logic [31:0] INSTANCE_ID_DEFAULT_CONST      = 32'h0000_0000;
    localparam logic [1:0]  AXI_RESP_OKAY_CONST            = 2'b00;
    localparam logic [1:0]  AXI_BURST_INCR_CONST           = 2'b01;

    typedef enum logic {
        XBAR_WRITE_DMA = 1'b0,
        XBAR_WRITE_CQ  = 1'b1
    } rdma_subsystem_write_grant_t;

endpackage

`default_nettype wire
