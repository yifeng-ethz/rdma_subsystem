// File name: rdma_subsystem_axi_xbar.sv
// Author  : Yifeng Wang (yifenwan@phys.ethz.ch)
// Version : 26.1.0
// Date    : 20260510
// Change  : add Phase 1 AXI4 xbar with SQ read merge and CQ write split

`default_nettype none

import rdma_subsystem_pkg::*;

module rdma_subsystem_axi_xbar #(
    parameter int unsigned DMA_DATA_W = DMA_DATA_W_DEFAULT_CONST,
    parameter int unsigned WQE_BUS_W  = WQE_BUS_W_DEFAULT_CONST
) (
    input  wire logic                       clk,
    input  wire logic                       reset_n,

    input  wire logic [3:0]                 sq_m_axi_arid,
    input  wire logic [63:0]                sq_m_axi_araddr,
    input  wire logic [7:0]                 sq_m_axi_arlen,
    input  wire logic [2:0]                 sq_m_axi_arsize,
    input  wire logic [1:0]                 sq_m_axi_arburst,
    input  wire logic                       sq_m_axi_arvalid,
    output logic                            sq_m_axi_arready,
    output logic [3:0]                      sq_m_axi_rid,
    output logic [WQE_BUS_W-1:0]            sq_m_axi_rdata,
    output logic [1:0]                      sq_m_axi_rresp,
    output logic                            sq_m_axi_rlast,
    output logic                            sq_m_axi_rvalid,
    input  wire logic                       sq_m_axi_rready,

    input  wire logic [3:0]                 dma_m_axi_awid,
    input  wire logic [63:0]                dma_m_axi_awaddr,
    input  wire logic [7:0]                 dma_m_axi_awlen,
    input  wire logic [2:0]                 dma_m_axi_awsize,
    input  wire logic [1:0]                 dma_m_axi_awburst,
    input  wire logic                       dma_m_axi_awvalid,
    output logic                            dma_m_axi_awready,
    input  wire logic [DMA_DATA_W-1:0]      dma_m_axi_wdata,
    input  wire logic [DMA_DATA_W/8-1:0]    dma_m_axi_wstrb,
    input  wire logic                       dma_m_axi_wlast,
    input  wire logic                       dma_m_axi_wvalid,
    output logic                            dma_m_axi_wready,
    output logic [3:0]                      dma_m_axi_bid,
    output logic [1:0]                      dma_m_axi_bresp,
    output logic                            dma_m_axi_bvalid,
    input  wire logic                       dma_m_axi_bready,

    input  wire logic [3:0]                 cq_m_axi_awid,
    input  wire logic [63:0]                cq_m_axi_awaddr,
    input  wire logic [7:0]                 cq_m_axi_awlen,
    input  wire logic [2:0]                 cq_m_axi_awsize,
    input  wire logic [1:0]                 cq_m_axi_awburst,
    input  wire logic                       cq_m_axi_awvalid,
    output logic                            cq_m_axi_awready,
    input  wire logic [WQE_BUS_W-1:0]       cq_m_axi_wdata,
    input  wire logic [WQE_BUS_W/8-1:0]     cq_m_axi_wstrb,
    input  wire logic                       cq_m_axi_wlast,
    input  wire logic                       cq_m_axi_wvalid,
    output logic                            cq_m_axi_wready,
    output logic [3:0]                      cq_m_axi_bid,
    output logic [1:0]                      cq_m_axi_bresp,
    output logic                            cq_m_axi_bvalid,
    input  wire logic                       cq_m_axi_bready,

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
    output logic                            m_axi_rready
);

    localparam int unsigned DMA_BYTES_CONST       = DMA_DATA_W / 8;
    localparam int unsigned WQE_RATIO_CONST       = WQE_BUS_W / DMA_DATA_W;
    localparam int unsigned WQE_RATIO_IDX_W_CONST =
        (WQE_RATIO_CONST <= 1) ? 1 : $clog2(WQE_RATIO_CONST);
    localparam logic [2:0] DMA_AXI_SIZE_CONST     = $clog2(DMA_BYTES_CONST);
    localparam logic [7:0] WQE_EXTERNAL_LEN_CONST = WQE_RATIO_CONST - 1;

    typedef enum logic [2:0] {
        WRITE_IDLING       = 3'd0,
        WRITE_DMA_SENDING  = 3'd1,
        WRITE_DMA_WAITING  = 3'd2,
        WRITE_CQ_CAPTURING = 3'd3,
        WRITE_CQ_SENDING   = 3'd4,
        WRITE_CQ_WAITING   = 3'd5
    } write_fsm_state_t;

    typedef enum logic [1:0] {
        READ_IDLING     = 2'd0,
        READ_COLLECTING = 2'd1,
        READ_RESPONDING = 2'd2
    } read_fsm_state_t;

    typedef struct packed {
        write_fsm_state_t             state;
        rdma_subsystem_write_grant_t  last_grant;
        logic [WQE_BUS_W-1:0]         cq_wdata;
        logic [WQE_BUS_W/8-1:0]       cq_wstrb;
        logic [WQE_RATIO_IDX_W_CONST-1:0] cq_beat_index;
    } write_state_t;

    typedef struct packed {
        read_fsm_state_t              state;
        logic [WQE_BUS_W-1:0]         rdata;
        logic [1:0]                   rresp;
        logic [3:0]                   rid;
        logic [WQE_RATIO_IDX_W_CONST-1:0] beat_index;
    } read_state_t;

    localparam write_state_t WRITE_RESET_CONST = '{
        state         : WRITE_IDLING,
        last_grant    : XBAR_WRITE_CQ,
        cq_wdata      : '0,
        cq_wstrb      : '0,
        cq_beat_index : '0
    };

    localparam read_state_t READ_RESET_CONST = '{
        state      : READ_IDLING,
        rdata      : '0,
        rresp      : AXI_RESP_OKAY_CONST,
        rid        : 4'h0,
        beat_index : '0
    };

    write_state_t write;
    read_state_t  read;

    rdma_subsystem_write_grant_t write_selected_grant;
    logic                        write_select_dma;
    logic                        write_select_cq;
    logic                        write_aw_handshake;
    logic                        dma_w_handshake;
    logic                        dma_b_handshake;
    logic                        cq_w_capture;
    logic                        cq_w_handshake;
    logic                        cq_b_handshake;
    logic                        read_ar_handshake;
    logic                        read_r_handshake;
    logic                        read_response_handshake;

    always_comb begin : write_grant_picker
        write_selected_grant = XBAR_WRITE_DMA;

        if (dma_m_axi_awvalid && cq_m_axi_awvalid) begin
            if (write.last_grant == XBAR_WRITE_DMA) begin
                write_selected_grant = XBAR_WRITE_CQ;
            end else begin
                write_selected_grant = XBAR_WRITE_DMA;
            end
        end else if (cq_m_axi_awvalid) begin
            write_selected_grant = XBAR_WRITE_CQ;
        end
    end

    assign write_select_dma       =
        (write.state == WRITE_IDLING) && (write_selected_grant == XBAR_WRITE_DMA) &&
        dma_m_axi_awvalid;
    assign write_select_cq        =
        (write.state == WRITE_IDLING) && (write_selected_grant == XBAR_WRITE_CQ) &&
        cq_m_axi_awvalid;
    assign write_aw_handshake     = m_axi_awvalid && m_axi_awready;
    assign dma_w_handshake        = dma_m_axi_wvalid && dma_m_axi_wready;
    assign dma_b_handshake        = dma_m_axi_bvalid && dma_m_axi_bready;
    assign cq_w_capture           = cq_m_axi_wvalid && cq_m_axi_wready;
    assign cq_w_handshake         = m_axi_wvalid && m_axi_wready &&
                                    (write.state == WRITE_CQ_SENDING);
    assign cq_b_handshake         = cq_m_axi_bvalid && cq_m_axi_bready;
    assign read_ar_handshake      = sq_m_axi_arvalid && sq_m_axi_arready;
    assign read_r_handshake       = m_axi_rvalid && m_axi_rready;
    assign read_response_handshake = sq_m_axi_rvalid && sq_m_axi_rready;

    assign dma_m_axi_awready = write_select_dma && m_axi_awready;
    assign cq_m_axi_awready  = write_select_cq && m_axi_awready;
    assign dma_m_axi_wready  = (write.state == WRITE_DMA_SENDING) && m_axi_wready;
    assign cq_m_axi_wready   = (write.state == WRITE_CQ_CAPTURING);

    assign dma_m_axi_bid     = m_axi_bid;
    assign dma_m_axi_bresp   = m_axi_bresp;
    assign dma_m_axi_bvalid  = (write.state == WRITE_DMA_WAITING) && m_axi_bvalid;
    assign cq_m_axi_bid      = m_axi_bid;
    assign cq_m_axi_bresp    = m_axi_bresp;
    assign cq_m_axi_bvalid   = (write.state == WRITE_CQ_WAITING) && m_axi_bvalid;
    assign m_axi_bready      =
        ((write.state == WRITE_DMA_WAITING) && dma_m_axi_bready) ||
        ((write.state == WRITE_CQ_WAITING) && cq_m_axi_bready);

    always_comb begin : host_write_mux
        m_axi_awid     = 4'h0;
        m_axi_awaddr   = 64'h0000_0000_0000_0000;
        m_axi_awlen    = 8'h00;
        m_axi_awsize   = DMA_AXI_SIZE_CONST;
        m_axi_awburst  = AXI_BURST_INCR_CONST;
        m_axi_awvalid  = 1'b0;
        m_axi_wdata    = '0;
        m_axi_wstrb    = '0;
        m_axi_wlast    = 1'b0;
        m_axi_wvalid   = 1'b0;

        if (write_select_dma) begin
            m_axi_awid    = dma_m_axi_awid;
            m_axi_awaddr  = dma_m_axi_awaddr;
            m_axi_awlen   = dma_m_axi_awlen;
            m_axi_awsize  = dma_m_axi_awsize;
            m_axi_awburst = dma_m_axi_awburst;
            m_axi_awvalid = dma_m_axi_awvalid;
        end else if (write_select_cq) begin
            m_axi_awid    = cq_m_axi_awid;
            m_axi_awaddr  = cq_m_axi_awaddr;
            m_axi_awlen   = WQE_EXTERNAL_LEN_CONST;
            m_axi_awsize  = DMA_AXI_SIZE_CONST;
            m_axi_awburst = cq_m_axi_awburst;
            m_axi_awvalid = cq_m_axi_awvalid;
        end

        if (write.state == WRITE_DMA_SENDING) begin
            m_axi_wdata  = dma_m_axi_wdata;
            m_axi_wstrb  = dma_m_axi_wstrb;
            m_axi_wlast  = dma_m_axi_wlast;
            m_axi_wvalid = dma_m_axi_wvalid;
        end else if (write.state == WRITE_CQ_SENDING) begin
            m_axi_wdata  =
                write.cq_wdata[write.cq_beat_index * DMA_DATA_W +: DMA_DATA_W];
            m_axi_wstrb  =
                write.cq_wstrb[write.cq_beat_index * DMA_BYTES_CONST +: DMA_BYTES_CONST];
            m_axi_wlast  = (write.cq_beat_index == (WQE_RATIO_CONST - 1));
            m_axi_wvalid = 1'b1;
        end
    end

    always_ff @(posedge clk or negedge reset_n) begin : write_fsm
        if (!reset_n) begin
            write <= WRITE_RESET_CONST;
        end else begin
            unique case (write.state)
                WRITE_IDLING: begin
                    if (write_aw_handshake && write_select_dma) begin
                        write.state         <= WRITE_DMA_SENDING;
                        write.last_grant    <= XBAR_WRITE_DMA;
                    end else if (write_aw_handshake && write_select_cq) begin
                        write.state         <= WRITE_CQ_CAPTURING;
                        write.last_grant    <= XBAR_WRITE_CQ;
                    end
                end

                WRITE_DMA_SENDING: begin
                    if (dma_w_handshake && dma_m_axi_wlast) begin
                        write.state <= WRITE_DMA_WAITING;
                    end
                end

                WRITE_DMA_WAITING: begin
                    if (dma_b_handshake) begin
                        write.state <= WRITE_IDLING;
                    end
                end

                WRITE_CQ_CAPTURING: begin
                    if (cq_w_capture) begin
                        write.cq_wdata         <= cq_m_axi_wdata;
                        write.cq_wstrb         <= cq_m_axi_wstrb;
                        write.cq_beat_index    <= '0;
                        write.state            <= WRITE_CQ_SENDING;
                    end
                end

                WRITE_CQ_SENDING: begin
                    if (cq_w_handshake) begin
                        if (write.cq_beat_index == (WQE_RATIO_CONST - 1)) begin
                            write.state <= WRITE_CQ_WAITING;
                        end else begin
                            write.cq_beat_index <= write.cq_beat_index + 1'b1;
                        end
                    end
                end

                WRITE_CQ_WAITING: begin
                    if (cq_b_handshake) begin
                        write.state <= WRITE_IDLING;
                    end
                end

                default: begin
                    write.state <= WRITE_IDLING;
                end
            endcase
        end
    end

    assign sq_m_axi_arready = (read.state == READ_IDLING) && m_axi_arready;
    assign m_axi_arid       = sq_m_axi_arid;
    assign m_axi_araddr     = sq_m_axi_araddr;
    assign m_axi_arlen      = WQE_EXTERNAL_LEN_CONST;
    assign m_axi_arsize     = DMA_AXI_SIZE_CONST;
    assign m_axi_arburst    = sq_m_axi_arburst;
    assign m_axi_arvalid    = (read.state == READ_IDLING) && sq_m_axi_arvalid;
    assign m_axi_rready     = (read.state == READ_COLLECTING);

    assign sq_m_axi_rid     = read.rid;
    assign sq_m_axi_rdata   = read.rdata;
    assign sq_m_axi_rresp   = read.rresp;
    assign sq_m_axi_rlast   = (read.state == READ_RESPONDING);
    assign sq_m_axi_rvalid  = (read.state == READ_RESPONDING);

    always_ff @(posedge clk or negedge reset_n) begin : read_fsm
        if (!reset_n) begin
            read <= READ_RESET_CONST;
        end else begin
            unique case (read.state)
                READ_IDLING: begin
                    if (read_ar_handshake) begin
                        read.rdata         <= '0;
                        read.rresp         <= AXI_RESP_OKAY_CONST;
                        read.rid           <= sq_m_axi_arid;
                        read.beat_index    <= '0;
                        read.state         <= READ_COLLECTING;
                    end
                end

                READ_COLLECTING: begin
                    if (read_r_handshake) begin
                        read.rdata[read.beat_index * DMA_DATA_W +: DMA_DATA_W]    <=
                            m_axi_rdata;

                        read.rresp    <= read.rresp | m_axi_rresp;
                        read.rid      <= m_axi_rid;

                        if ((read.beat_index == (WQE_RATIO_CONST - 1)) || m_axi_rlast) begin
                            read.state <= READ_RESPONDING;
                        end else begin
                            read.beat_index <= read.beat_index + 1'b1;
                        end
                    end
                end

                READ_RESPONDING: begin
                    if (read_response_handshake) begin
                        read.state <= READ_IDLING;
                    end
                end

                default: begin
                    read.state <= READ_IDLING;
                end
            endcase
        end
    end

    // synthesis translate_off
    always_ff @(posedge clk) begin : protocol_assertions
        if (reset_n) begin
            if (cq_w_capture) begin
                assert (cq_m_axi_wlast);
            end
            if (read_ar_handshake) begin
                assert (sq_m_axi_arlen == 8'h00);
                assert (sq_m_axi_arsize == $clog2(WQE_BUS_W / 8));
            end
            if (write_aw_handshake && write_select_cq) begin
                assert (cq_m_axi_awlen == 8'h00);
                assert (cq_m_axi_awsize == $clog2(WQE_BUS_W / 8));
            end
        end
    end

    initial begin : parameter_sanity
        assert (WQE_BUS_W % DMA_DATA_W == 0)
            else $fatal(1, "WQE_BUS_W must be an integer multiple of DMA_DATA_W");
        assert (WQE_RATIO_CONST == 2)
            else $fatal(1, "Phase 1 rdma_subsystem_axi_xbar expects 512b WQE over 256b host");
    end
    // synthesis translate_on

endmodule

`default_nettype wire
