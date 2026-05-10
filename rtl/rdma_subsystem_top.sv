// File name: rdma_subsystem_top.sv
// Author  : Yifeng Wang (yifenwan@phys.ethz.ch)
// Version : 26.1.0
// Date    : 20260510
// Change  : wire RDMA supercore top around four sibling IPs and xbar

`default_nettype none

import rdma_subsystem_pkg::*;

module rdma_subsystem_top #(
    parameter int unsigned DMA_DATA_W    = DMA_DATA_W_DEFAULT_CONST,
    parameter int unsigned WQE_BUS_W     = WQE_BUS_W_DEFAULT_CONST,
    parameter int unsigned DEBUG_LEVEL   = 0,
    parameter logic [31:0] IP_UID        = IP_UID_DEFAULT_CONST,
    parameter int unsigned VERSION_MAJOR = VERSION_MAJOR_DEFAULT_CONST,
    parameter int unsigned VERSION_MINOR = VERSION_MINOR_DEFAULT_CONST,
    parameter int unsigned VERSION_PATCH = VERSION_PATCH_DEFAULT_CONST,
    parameter int unsigned BUILD         = BUILD_DEFAULT_CONST,
    parameter logic [31:0] VERSION_DATE  = VERSION_DATE_DEFAULT_CONST,
    parameter logic [31:0] VERSION_GIT   = VERSION_GIT_DEFAULT_CONST,
    parameter logic [31:0] INSTANCE_ID   = INSTANCE_ID_DEFAULT_CONST
) (
    input  wire logic                       clk,
    input  wire logic                       reset_n,

    input  wire logic [35:0]                s_axis_opq_tdata,
    input  wire logic                       s_axis_opq_tvalid,
    output logic                            s_axis_opq_tready,
    input  wire logic                       s_axis_opq_tlast,
    input  wire logic [1:0]                 s_axis_opq_tuser,

    input  wire logic [7:0]                 s_axil_awaddr,
    input  wire logic                       s_axil_awvalid,
    output logic                            s_axil_awready,
    input  wire logic [31:0]                s_axil_wdata,
    input  wire logic [3:0]                 s_axil_wstrb,
    input  wire logic                       s_axil_wvalid,
    output logic                            s_axil_wready,
    output logic [1:0]                      s_axil_bresp,
    output logic                            s_axil_bvalid,
    input  wire logic                       s_axil_bready,
    input  wire logic [7:0]                 s_axil_araddr,
    input  wire logic                       s_axil_arvalid,
    output logic                            s_axil_arready,
    output logic [31:0]                     s_axil_rdata,
    output logic [1:0]                      s_axil_rresp,
    output logic                            s_axil_rvalid,
    input  wire logic                       s_axil_rready,

    output logic [3:0]                      m_axi_awid,
    output logic [63:0]                     m_axi_awaddr,
    output logic [7:0]                      m_axi_awlen,
    output logic [2:0]                      m_axi_awsize,
    output logic [1:0]                      m_axi_awburst,
    output logic                            m_axi_awvalid,
    input  wire logic                       m_axi_awready,
    output logic [DMA_DATA_W-1:0]           m_axi_wdata,
    output logic [DMA_DATA_W/8-1:0]         m_axi_wstrb,
    output logic                            m_axi_wlast,
    output logic                            m_axi_wvalid,
    input  wire logic                       m_axi_wready,
    input  wire logic [3:0]                 m_axi_bid,
    input  wire logic [1:0]                 m_axi_bresp,
    input  wire logic                       m_axi_bvalid,
    output logic                            m_axi_bready,
    output logic [3:0]                      m_axi_arid,
    output logic [63:0]                     m_axi_araddr,
    output logic [7:0]                      m_axi_arlen,
    output logic [2:0]                      m_axi_arsize,
    output logic [1:0]                      m_axi_arburst,
    output logic                            m_axi_arvalid,
    input  wire logic                       m_axi_arready,
    input  wire logic [3:0]                 m_axi_rid,
    input  wire logic [DMA_DATA_W-1:0]      m_axi_rdata,
    input  wire logic [1:0]                 m_axi_rresp,
    input  wire logic                       m_axi_rlast,
    input  wire logic                       m_axi_rvalid,
    output logic                            m_axi_rready,

    output logic                            msix_req,
    output logic [4:0]                      msix_vector,
    input  wire logic                       msix_ack
);

    localparam int unsigned DMA_DBG2_META_W_CONST = 136;
    localparam int unsigned CQ_DBG_META_W_CONST   = 64;

    logic                         sq_fetcher_reset_n;
    logic                         dma_engine_reset_n;
    logic                         cq_pusher_reset_n;
    logic                         run_manager_reset_n;
    logic                         xbar_reset_n;
    logic                         csr_decoder_reset_n;

    logic [7:0]                   rm_s_axil_awaddr;
    logic                         rm_s_axil_awvalid;
    logic                         rm_s_axil_awready;
    logic [31:0]                  rm_s_axil_wdata;
    logic [3:0]                   rm_s_axil_wstrb;
    logic                         rm_s_axil_wvalid;
    logic                         rm_s_axil_wready;
    logic [1:0]                   rm_s_axil_bresp;
    logic                         rm_s_axil_bvalid;
    logic                         rm_s_axil_bready;
    logic [7:0]                   rm_s_axil_araddr;
    logic                         rm_s_axil_arvalid;
    logic                         rm_s_axil_arready;
    logic [31:0]                  rm_s_axil_rdata;
    logic [1:0]                   rm_s_axil_rresp;
    logic                         rm_s_axil_rvalid;
    logic                         rm_s_axil_rready;

    logic [63:0]                  sqf_cfg_sq_base;
    logic [15:0]                  sqf_cfg_sq_depth;
    logic                         sqf_cfg_enable;
    logic                         sqf_sq_tail_dbl_pulse;
    logic [15:0]                  sqf_sq_tail_dbl_value;
    logic [WQE_BUS_W-1:0]         sqe_tdata;
    logic                         sqe_tvalid;
    logic                         sqe_tready;
    logic                         sqe_tlast;
    logic [15:0]                  sqe_tuser;
    logic [31:0]                  sqf_cnt_sqe_fetched;
    logic [15:0]                  sqf_cur_sq_head;

    logic                         dma_job_req;
    logic [63:0]                  dma_job_seg0_addr;
    logic [63:0]                  dma_job_seg0_span;
    logic [63:0]                  dma_job_seg1_addr;
    logic [63:0]                  dma_job_seg1_span;
    logic [15:0]                  dma_job_sqe_id;
    logic [15:0]                  dma_job_opcode;
    logic                         dma_job_done;
    logic [63:0]                  dma_job_bytes_written_total;
    logic [31:0]                  dma_job_seg0_bytes_written;
    logic [31:0]                  dma_job_seg1_bytes_written;
    logic [15:0]                  dma_job_status;
    logic [15:0]                  dma_job_sqe_id_echo;
    logic [31:0]                  dma_job_event_count;
    logic [63:0]                  dma_job_first_event_ts;
    logic [63:0]                  dma_job_last_event_ts;
    logic [31:0]                  dma_cnt_input_w;
    logic [31:0]                  dma_cnt_bytes_written;
    logic [31:0]                  dma_cnt_halt;
    logic [31:0]                  dma_cnt_eoe_observed;
    logic                         reset_counters_pulse;

    logic [63:0]                  cqp_cfg_cq_base;
    logic [15:0]                  cqp_cfg_cq_depth;
    logic                         cqp_cfg_enable;
    logic                         cqp_cq_head_dbl_pulse;
    logic [15:0]                  cqp_cq_head_dbl_value;
    logic [WQE_BUS_W-1:0]         cqe_tdata;
    logic                         cqe_tvalid;
    logic                         cqe_tready;
    logic                         cqe_tlast;
    logic [15:0]                  cqe_tuser;
    logic [15:0]                  cqp_cq_tail;
    logic [31:0]                  cqp_cnt_cqe_posted;

    logic [3:0]                   sq_axi_arid;
    logic [63:0]                  sq_axi_araddr;
    logic [7:0]                   sq_axi_arlen;
    logic [2:0]                   sq_axi_arsize;
    logic [1:0]                   sq_axi_arburst;
    logic                         sq_axi_arvalid;
    logic                         sq_axi_arready;
    logic [3:0]                   sq_axi_rid;
    logic [WQE_BUS_W-1:0]         sq_axi_rdata;
    logic [1:0]                   sq_axi_rresp;
    logic                         sq_axi_rlast;
    logic                         sq_axi_rvalid;
    logic                         sq_axi_rready;

    logic [3:0]                   dma_axi_awid;
    logic [63:0]                  dma_axi_awaddr;
    logic [7:0]                   dma_axi_awlen;
    logic [2:0]                   dma_axi_awsize;
    logic [1:0]                   dma_axi_awburst;
    logic                         dma_axi_awvalid;
    logic                         dma_axi_awready;
    logic [DMA_DATA_W-1:0]        dma_axi_wdata;
    logic [DMA_DATA_W/8-1:0]      dma_axi_wstrb;
    logic                         dma_axi_wlast;
    logic                         dma_axi_wvalid;
    logic                         dma_axi_wready;
    logic [3:0]                   dma_axi_bid;
    logic [1:0]                   dma_axi_bresp;
    logic                         dma_axi_bvalid;
    logic                         dma_axi_bready;

    logic [3:0]                   cq_axi_awid;
    logic [63:0]                  cq_axi_awaddr;
    logic [7:0]                   cq_axi_awlen;
    logic [2:0]                   cq_axi_awsize;
    logic [1:0]                   cq_axi_awburst;
    logic                         cq_axi_awvalid;
    logic                         cq_axi_awready;
    logic [WQE_BUS_W-1:0]         cq_axi_wdata;
    logic [WQE_BUS_W/8-1:0]       cq_axi_wstrb;
    logic                         cq_axi_wlast;
    logic                         cq_axi_wvalid;
    logic                         cq_axi_wready;
    logic [3:0]                   cq_axi_bid;
    logic [1:0]                   cq_axi_bresp;
    logic                         cq_axi_bvalid;
    logic                         cq_axi_bready;

    logic [15:0]                  rm_dbg2_sidecar_sqe_id;
    logic [31:0]                  rm_dbg2_sidecar_dma_done_seq;
    logic [31:0]                  rm_dbg2_sidecar_push_seq;
    logic [31:0]                  rm_dbg2_sidecar_retire_seq;
    logic [CQ_DBG_META_W_CONST-1:0] cqe_dbg_meta;

    assign cqe_dbg_meta = {
        rm_dbg2_sidecar_push_seq[15:0],
        rm_dbg2_sidecar_dma_done_seq[15:0],
        rm_dbg2_sidecar_retire_seq[15:0],
        rm_dbg2_sidecar_sqe_id
    };

    rdma_subsystem_reset_chain reset_chain_i (
        .clk                (clk),
        .reset_n            (reset_n),
        .sq_fetcher_reset_n (sq_fetcher_reset_n),
        .dma_engine_reset_n (dma_engine_reset_n),
        .cq_pusher_reset_n  (cq_pusher_reset_n),
        .run_manager_reset_n(run_manager_reset_n),
        .xbar_reset_n       (xbar_reset_n),
        .csr_decoder_reset_n(csr_decoder_reset_n)
    );

    rdma_subsystem_csr_decoder csr_decoder_i (
        .reset_n        (csr_decoder_reset_n),
        .s_axil_awaddr  (s_axil_awaddr),
        .s_axil_awvalid (s_axil_awvalid),
        .s_axil_awready (s_axil_awready),
        .s_axil_wdata   (s_axil_wdata),
        .s_axil_wstrb   (s_axil_wstrb),
        .s_axil_wvalid  (s_axil_wvalid),
        .s_axil_wready  (s_axil_wready),
        .s_axil_bresp   (s_axil_bresp),
        .s_axil_bvalid  (s_axil_bvalid),
        .s_axil_bready  (s_axil_bready),
        .s_axil_araddr  (s_axil_araddr),
        .s_axil_arvalid (s_axil_arvalid),
        .s_axil_arready (s_axil_arready),
        .s_axil_rdata   (s_axil_rdata),
        .s_axil_rresp   (s_axil_rresp),
        .s_axil_rvalid  (s_axil_rvalid),
        .s_axil_rready  (s_axil_rready),
        .m_axil_awaddr  (rm_s_axil_awaddr),
        .m_axil_awvalid (rm_s_axil_awvalid),
        .m_axil_awready (rm_s_axil_awready),
        .m_axil_wdata   (rm_s_axil_wdata),
        .m_axil_wstrb   (rm_s_axil_wstrb),
        .m_axil_wvalid  (rm_s_axil_wvalid),
        .m_axil_wready  (rm_s_axil_wready),
        .m_axil_bresp   (rm_s_axil_bresp),
        .m_axil_bvalid  (rm_s_axil_bvalid),
        .m_axil_bready  (rm_s_axil_bready),
        .m_axil_araddr  (rm_s_axil_araddr),
        .m_axil_arvalid (rm_s_axil_arvalid),
        .m_axil_arready (rm_s_axil_arready),
        .m_axil_rdata   (rm_s_axil_rdata),
        .m_axil_rresp   (rm_s_axil_rresp),
        .m_axil_rvalid  (rm_s_axil_rvalid),
        .m_axil_rready  (rm_s_axil_rready)
    );

    rdma_run_manager #(
        .WQE_BUS_W    (WQE_BUS_W),
        .DEBUG_LEVEL  (DEBUG_LEVEL),
        .IP_UID       (IP_UID),
        .VERSION_MAJOR(VERSION_MAJOR),
        .VERSION_MINOR(VERSION_MINOR),
        .VERSION_PATCH(VERSION_PATCH),
        .BUILD        (BUILD),
        .VERSION_DATE (VERSION_DATE),
        .VERSION_GIT  (VERSION_GIT),
        .INSTANCE_ID  (INSTANCE_ID)
    ) run_manager_i (
        .clk                         (clk),
        .reset_n                     (run_manager_reset_n),
        .s_axil_awaddr               (rm_s_axil_awaddr),
        .s_axil_awvalid              (rm_s_axil_awvalid),
        .s_axil_awready              (rm_s_axil_awready),
        .s_axil_wdata                (rm_s_axil_wdata),
        .s_axil_wstrb                (rm_s_axil_wstrb),
        .s_axil_wvalid               (rm_s_axil_wvalid),
        .s_axil_wready               (rm_s_axil_wready),
        .s_axil_bresp                (rm_s_axil_bresp),
        .s_axil_bvalid               (rm_s_axil_bvalid),
        .s_axil_bready               (rm_s_axil_bready),
        .s_axil_araddr               (rm_s_axil_araddr),
        .s_axil_arvalid              (rm_s_axil_arvalid),
        .s_axil_arready              (rm_s_axil_arready),
        .s_axil_rdata                (rm_s_axil_rdata),
        .s_axil_rresp                (rm_s_axil_rresp),
        .s_axil_rvalid               (rm_s_axil_rvalid),
        .s_axil_rready               (rm_s_axil_rready),
        .sqf_cfg_sq_base             (sqf_cfg_sq_base),
        .sqf_cfg_sq_depth            (sqf_cfg_sq_depth),
        .sqf_cfg_enable              (sqf_cfg_enable),
        .sqf_sq_tail_dbl_pulse       (sqf_sq_tail_dbl_pulse),
        .sqf_sq_tail_dbl_value       (sqf_sq_tail_dbl_value),
        .s_axis_sqe_tdata            (sqe_tdata),
        .s_axis_sqe_tvalid           (sqe_tvalid),
        .s_axis_sqe_tready           (sqe_tready),
        .s_axis_sqe_tlast            (sqe_tlast),
        .s_axis_sqe_tuser            (sqe_tuser),
        .sqf_cnt_sqe_fetched         (sqf_cnt_sqe_fetched),
        .sqf_cur_sq_head             (sqf_cur_sq_head),
        .dma_job_req                 (dma_job_req),
        .dma_job_seg0_addr           (dma_job_seg0_addr),
        .dma_job_seg0_span           (dma_job_seg0_span),
        .dma_job_seg1_addr           (dma_job_seg1_addr),
        .dma_job_seg1_span           (dma_job_seg1_span),
        .dma_job_sqe_id              (dma_job_sqe_id),
        .dma_job_opcode              (dma_job_opcode),
        .dma_job_done                (dma_job_done),
        .dma_job_bytes_written_total (dma_job_bytes_written_total),
        .dma_job_seg0_bytes_written  (dma_job_seg0_bytes_written),
        .dma_job_seg1_bytes_written  (dma_job_seg1_bytes_written),
        .dma_job_status              (dma_job_status),
        .dma_job_sqe_id_echo         (dma_job_sqe_id_echo),
        .dma_job_event_count         (dma_job_event_count),
        .dma_job_first_event_ts      (dma_job_first_event_ts),
        .dma_job_last_event_ts       (dma_job_last_event_ts),
        .dma_cnt_input_w             (dma_cnt_input_w),
        .dma_cnt_bytes_written       (dma_cnt_bytes_written),
        .dma_cnt_halt                (dma_cnt_halt),
        .dma_cnt_eoe_observed        (dma_cnt_eoe_observed),
        .dma_opq_drop_snapshot       (64'h0000_0000_0000_0000),
        .cqp_cfg_cq_base             (cqp_cfg_cq_base),
        .cqp_cfg_cq_depth            (cqp_cfg_cq_depth),
        .cqp_cfg_enable              (cqp_cfg_enable),
        .cqp_cq_head_dbl_pulse       (cqp_cq_head_dbl_pulse),
        .cqp_cq_head_dbl_value       (cqp_cq_head_dbl_value),
        .m_axis_cqe_tdata            (cqe_tdata),
        .m_axis_cqe_tvalid           (cqe_tvalid),
        .m_axis_cqe_tready           (cqe_tready),
        .m_axis_cqe_tlast            (cqe_tlast),
        .m_axis_cqe_tuser            (cqe_tuser),
        .cqp_cq_tail                 (cqp_cq_tail),
        .cqp_cnt_cqe_posted          (cqp_cnt_cqe_posted),
        .reset_counters_pulse        (reset_counters_pulse),
        .dbg_fsm_state               (),
        .dbg_sqe_valid               (),
        .dbg_sqe_ready               (),
        .dbg_dma_job_req             (),
        .dbg_dma_job_done            (),
        .dbg_cqe_valid               (),
        .dbg_cqe_ready               (),
        .dbg_ctrl_halt               (),
        .dbg_sqe_accept_count        (),
        .dbg_cqe_accept_count        (),
        .dbg2_sidecar_valid          (),
        .dbg2_sidecar_sqe_id         (rm_dbg2_sidecar_sqe_id),
        .dbg2_sidecar_fetch_seq      (),
        .dbg2_sidecar_job_seq        (),
        .dbg2_sidecar_dma_done_seq   (rm_dbg2_sidecar_dma_done_seq),
        .dbg2_sidecar_push_seq       (rm_dbg2_sidecar_push_seq),
        .dbg2_sidecar_retire_seq     (rm_dbg2_sidecar_retire_seq)
    );

    rdma_sq_fetcher #(
        .WQE_BUS_W     (WQE_BUS_W),
        .SQ_BURST_BEATS(1),
        .DEBUG         (DEBUG_LEVEL)
    ) sq_fetcher_i (
        .clk                              (clk),
        .reset_n                          (sq_fetcher_reset_n),
        .cfg_sq_base                      (sqf_cfg_sq_base),
        .cfg_sq_depth                     (sqf_cfg_sq_depth),
        .cfg_enable                       (sqf_cfg_enable),
        .sq_tail_dbl_pulse                (sqf_sq_tail_dbl_pulse),
        .sq_tail_dbl_value                (sqf_sq_tail_dbl_value),
        .m_axis_sqe_tdata                 (sqe_tdata),
        .m_axis_sqe_tvalid                (sqe_tvalid),
        .m_axis_sqe_tready                (sqe_tready),
        .m_axis_sqe_tlast                 (sqe_tlast),
        .m_axis_sqe_tuser                 (sqe_tuser),
        .m_axi_arid                       (sq_axi_arid),
        .m_axi_araddr                     (sq_axi_araddr),
        .m_axi_arlen                      (sq_axi_arlen),
        .m_axi_arsize                     (sq_axi_arsize),
        .m_axi_arburst                    (sq_axi_arburst),
        .m_axi_arvalid                    (sq_axi_arvalid),
        .m_axi_arready                    (sq_axi_arready),
        .m_axi_rid                        (sq_axi_rid),
        .m_axi_rdata                      (sq_axi_rdata),
        .m_axi_rresp                      (sq_axi_rresp),
        .m_axi_rlast                      (sq_axi_rlast),
        .m_axi_rvalid                     (sq_axi_rvalid),
        .m_axi_rready                     (sq_axi_rready),
        .cnt_sqe_fetched                  (sqf_cnt_sqe_fetched),
        .cur_sq_head                      (sqf_cur_sq_head),
        .dbg_cur_sq_head                  (),
        .dbg_cur_sq_tail                  (),
        .dbg_sqe_in_flight                (),
        .dbg_ar_pending                   (),
        .dbg_emit_backpressure_stall_cnt  (),
        .dbg_fsm_state                    (),
        .dbg2_sidecar_valid               (),
        .dbg2_sidecar_sqe_id              (),
        .dbg2_sidecar_fetch_seq           (),
        .dbg2_sidecar_ring_slot           (),
        .dbg2_sidecar_doorbell_seq        ()
    );

    rdma_dma_engine #(
        .DMA_DATA_W                (DMA_DATA_W),
        .MAX_BURST_BEATS           (16),
        .SEG_QUANTUM_BYTES         (4096),
        .FIFO_DEPTH                (256),
        .FIFO_ALMOST_FULL_THRESHOLD(192),
        .DBG2_META_W               (DMA_DBG2_META_W_CONST),
        .DEBUG_LEVEL               (DEBUG_LEVEL)
    ) dma_engine_i (
        .clk                    (clk),
        .reset_n                (dma_engine_reset_n),
        .s_axis_opq_tdata       (s_axis_opq_tdata),
        .s_axis_opq_tvalid      (s_axis_opq_tvalid),
        .s_axis_opq_tready      (s_axis_opq_tready),
        .s_axis_opq_tlast       (s_axis_opq_tlast),
        .s_axis_opq_tuser       (s_axis_opq_tuser),
        .job_req                (dma_job_req),
        .job_seg0_addr          (dma_job_seg0_addr),
        .job_seg0_span          (dma_job_seg0_span),
        .job_seg1_addr          (dma_job_seg1_addr),
        .job_seg1_span          (dma_job_seg1_span),
        .job_sqe_id             (dma_job_sqe_id),
        .job_opcode             (dma_job_opcode),
        .job_done               (dma_job_done),
        .job_bytes_written_total(dma_job_bytes_written_total),
        .job_seg0_bytes_written (dma_job_seg0_bytes_written),
        .job_seg1_bytes_written (dma_job_seg1_bytes_written),
        .job_status             (dma_job_status),
        .job_sqe_id_echo        (dma_job_sqe_id_echo),
        .job_event_count        (dma_job_event_count),
        .job_first_event_ts     (dma_job_first_event_ts),
        .job_last_event_ts      (dma_job_last_event_ts),
        .m_axi_awid             (dma_axi_awid),
        .m_axi_awaddr           (dma_axi_awaddr),
        .m_axi_awlen            (dma_axi_awlen),
        .m_axi_awsize           (dma_axi_awsize),
        .m_axi_awburst          (dma_axi_awburst),
        .m_axi_awvalid          (dma_axi_awvalid),
        .m_axi_awready          (dma_axi_awready),
        .m_axi_wdata            (dma_axi_wdata),
        .m_axi_wstrb            (dma_axi_wstrb),
        .m_axi_wlast            (dma_axi_wlast),
        .m_axi_wvalid           (dma_axi_wvalid),
        .m_axi_wready           (dma_axi_wready),
        .m_axi_bid              (dma_axi_bid),
        .m_axi_bresp            (dma_axi_bresp),
        .m_axi_bvalid           (dma_axi_bvalid),
        .m_axi_bready           (dma_axi_bready),
        .clear_counters         (reset_counters_pulse),
        .cnt_input_w            (dma_cnt_input_w),
        .cnt_bytes_written      (dma_cnt_bytes_written),
        .cnt_halt               (dma_cnt_halt),
        .cnt_eoe_observed       (dma_cnt_eoe_observed),
        .dbg1_fifo_level        (),
        .dbg1_fifo_almost_full  (),
        .dbg1_packer_slot       (),
        .dbg1_packer_pending_eoe(),
        .dbg1_aw_inflight       (),
        .dbg1_w_beats_remaining(),
        .dbg1_b_outstanding     (),
        .dbg1_halt_pulse        (),
        .dbg1_writer_state      (),
        .dbg2_meta_valid        (1'b0),
        .dbg2_meta              ('0),
        .dbg2_writer_meta_valid (),
        .dbg2_writer_meta       (),
        .dbg2_writer_valid_mask ()
    );

    rdma_cq_pusher #(
        .WQE_BUS_W  (WQE_BUS_W),
        .DEBUG_LEVEL(DEBUG_LEVEL),
        .DBG_META_W (CQ_DBG_META_W_CONST)
    ) cq_pusher_i (
        .clk                   (clk),
        .reset_n               (cq_pusher_reset_n),
        .cfg_cq_base           (cqp_cfg_cq_base),
        .cfg_cq_depth          (cqp_cfg_cq_depth),
        .cfg_enable            (cqp_cfg_enable),
        .cq_head_dbl_pulse     (cqp_cq_head_dbl_pulse),
        .cq_head_dbl_value     (cqp_cq_head_dbl_value),
        .s_axis_cqe_tdata      (cqe_tdata),
        .s_axis_cqe_tvalid     (cqe_tvalid),
        .s_axis_cqe_tready     (cqe_tready),
        .s_axis_cqe_tlast      (cqe_tlast),
        .s_axis_cqe_tuser      (cqe_tuser),
        .cq_tail               (cqp_cq_tail),
        .m_axi_awid            (cq_axi_awid),
        .m_axi_awaddr          (cq_axi_awaddr),
        .m_axi_awlen           (cq_axi_awlen),
        .m_axi_awsize          (cq_axi_awsize),
        .m_axi_awburst         (cq_axi_awburst),
        .m_axi_awvalid         (cq_axi_awvalid),
        .m_axi_awready         (cq_axi_awready),
        .m_axi_wdata           (cq_axi_wdata),
        .m_axi_wstrb           (cq_axi_wstrb),
        .m_axi_wlast           (cq_axi_wlast),
        .m_axi_wvalid          (cq_axi_wvalid),
        .m_axi_wready          (cq_axi_wready),
        .m_axi_bid             (cq_axi_bid),
        .m_axi_bresp           (cq_axi_bresp),
        .m_axi_bvalid          (cq_axi_bvalid),
        .m_axi_bready          (cq_axi_bready),
        .msix_req              (msix_req),
        .msix_vector           (msix_vector),
        .msix_ack              (msix_ack),
        .cnt_cqe_posted        (cqp_cnt_cqe_posted),
        .dbg_cur_cq_tail       (),
        .dbg_cur_cq_head_credit(),
        .dbg_cq_full           (),
        .dbg_aw_pending        (),
        .dbg_b_inflight        (),
        .dbg_ring_full_stall_cyc(),
        .dbg_state             (),
        .dbg_cnt_bresp_error   ()
        // synthesis translate_off
        , .s_axis_cqe_tuser_meta(cqe_dbg_meta)
        , .dbg_last_pushed_meta ()
        // synthesis translate_on
    );

    rdma_subsystem_axi_xbar #(
        .DMA_DATA_W(DMA_DATA_W),
        .WQE_BUS_W (WQE_BUS_W)
    ) axi_xbar_i (
        .clk              (clk),
        .reset_n          (xbar_reset_n),
        .sq_m_axi_arid    (sq_axi_arid),
        .sq_m_axi_araddr  (sq_axi_araddr),
        .sq_m_axi_arlen   (sq_axi_arlen),
        .sq_m_axi_arsize  (sq_axi_arsize),
        .sq_m_axi_arburst (sq_axi_arburst),
        .sq_m_axi_arvalid (sq_axi_arvalid),
        .sq_m_axi_arready (sq_axi_arready),
        .sq_m_axi_rid     (sq_axi_rid),
        .sq_m_axi_rdata   (sq_axi_rdata),
        .sq_m_axi_rresp   (sq_axi_rresp),
        .sq_m_axi_rlast   (sq_axi_rlast),
        .sq_m_axi_rvalid  (sq_axi_rvalid),
        .sq_m_axi_rready  (sq_axi_rready),
        .dma_m_axi_awid   (dma_axi_awid),
        .dma_m_axi_awaddr (dma_axi_awaddr),
        .dma_m_axi_awlen  (dma_axi_awlen),
        .dma_m_axi_awsize (dma_axi_awsize),
        .dma_m_axi_awburst(dma_axi_awburst),
        .dma_m_axi_awvalid(dma_axi_awvalid),
        .dma_m_axi_awready(dma_axi_awready),
        .dma_m_axi_wdata  (dma_axi_wdata),
        .dma_m_axi_wstrb  (dma_axi_wstrb),
        .dma_m_axi_wlast  (dma_axi_wlast),
        .dma_m_axi_wvalid (dma_axi_wvalid),
        .dma_m_axi_wready (dma_axi_wready),
        .dma_m_axi_bid    (dma_axi_bid),
        .dma_m_axi_bresp  (dma_axi_bresp),
        .dma_m_axi_bvalid (dma_axi_bvalid),
        .dma_m_axi_bready (dma_axi_bready),
        .cq_m_axi_awid    (cq_axi_awid),
        .cq_m_axi_awaddr  (cq_axi_awaddr),
        .cq_m_axi_awlen   (cq_axi_awlen),
        .cq_m_axi_awsize  (cq_axi_awsize),
        .cq_m_axi_awburst (cq_axi_awburst),
        .cq_m_axi_awvalid (cq_axi_awvalid),
        .cq_m_axi_awready (cq_axi_awready),
        .cq_m_axi_wdata   (cq_axi_wdata),
        .cq_m_axi_wstrb   (cq_axi_wstrb),
        .cq_m_axi_wlast   (cq_axi_wlast),
        .cq_m_axi_wvalid  (cq_axi_wvalid),
        .cq_m_axi_wready  (cq_axi_wready),
        .cq_m_axi_bid     (cq_axi_bid),
        .cq_m_axi_bresp   (cq_axi_bresp),
        .cq_m_axi_bvalid  (cq_axi_bvalid),
        .cq_m_axi_bready  (cq_axi_bready),
        .m_axi_awid       (m_axi_awid),
        .m_axi_awaddr     (m_axi_awaddr),
        .m_axi_awlen      (m_axi_awlen),
        .m_axi_awsize     (m_axi_awsize),
        .m_axi_awburst    (m_axi_awburst),
        .m_axi_awvalid    (m_axi_awvalid),
        .m_axi_awready    (m_axi_awready),
        .m_axi_wdata      (m_axi_wdata),
        .m_axi_wstrb      (m_axi_wstrb),
        .m_axi_wlast      (m_axi_wlast),
        .m_axi_wvalid     (m_axi_wvalid),
        .m_axi_wready     (m_axi_wready),
        .m_axi_bid        (m_axi_bid),
        .m_axi_bresp      (m_axi_bresp),
        .m_axi_bvalid     (m_axi_bvalid),
        .m_axi_bready     (m_axi_bready),
        .m_axi_arid       (m_axi_arid),
        .m_axi_araddr     (m_axi_araddr),
        .m_axi_arlen      (m_axi_arlen),
        .m_axi_arsize     (m_axi_arsize),
        .m_axi_arburst    (m_axi_arburst),
        .m_axi_arvalid    (m_axi_arvalid),
        .m_axi_arready    (m_axi_arready),
        .m_axi_rid        (m_axi_rid),
        .m_axi_rdata      (m_axi_rdata),
        .m_axi_rresp      (m_axi_rresp),
        .m_axi_rlast      (m_axi_rlast),
        .m_axi_rvalid     (m_axi_rvalid),
        .m_axi_rready     (m_axi_rready)
    );

endmodule

`default_nettype wire
