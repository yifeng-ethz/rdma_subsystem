`ifndef RDMA_SUBSYSTEM_IF_SV
`define RDMA_SUBSYSTEM_IF_SV

interface rdma_subsystem_if #(
  parameter int unsigned DMA_DATA_W = 256
) (
  input logic clk
);
  logic reset_n;

  logic [35:0]                s_axis_opq_tdata;
  logic                       s_axis_opq_tvalid;
  logic                       s_axis_opq_tready;
  logic                       s_axis_opq_tlast;
  logic [1:0]                 s_axis_opq_tuser;

  logic [7:0]                 s_axil_awaddr;
  logic                       s_axil_awvalid;
  logic                       s_axil_awready;
  logic [31:0]                s_axil_wdata;
  logic [3:0]                 s_axil_wstrb;
  logic                       s_axil_wvalid;
  logic                       s_axil_wready;
  logic [1:0]                 s_axil_bresp;
  logic                       s_axil_bvalid;
  logic                       s_axil_bready;
  logic [7:0]                 s_axil_araddr;
  logic                       s_axil_arvalid;
  logic                       s_axil_arready;
  logic [31:0]                s_axil_rdata;
  logic [1:0]                 s_axil_rresp;
  logic                       s_axil_rvalid;
  logic                       s_axil_rready;

  logic [3:0]                 m_axi_awid;
  logic [63:0]                m_axi_awaddr;
  logic [7:0]                 m_axi_awlen;
  logic [2:0]                 m_axi_awsize;
  logic [1:0]                 m_axi_awburst;
  logic                       m_axi_awvalid;
  logic                       m_axi_awready;
  logic [DMA_DATA_W-1:0]      m_axi_wdata;
  logic [DMA_DATA_W/8-1:0]    m_axi_wstrb;
  logic                       m_axi_wlast;
  logic                       m_axi_wvalid;
  logic                       m_axi_wready;
  logic [3:0]                 m_axi_bid;
  logic [1:0]                 m_axi_bresp;
  logic                       m_axi_bvalid;
  logic                       m_axi_bready;
  logic [3:0]                 m_axi_arid;
  logic [63:0]                m_axi_araddr;
  logic [7:0]                 m_axi_arlen;
  logic [2:0]                 m_axi_arsize;
  logic [1:0]                 m_axi_arburst;
  logic                       m_axi_arvalid;
  logic                       m_axi_arready;
  logic [3:0]                 m_axi_rid;
  logic [DMA_DATA_W-1:0]      m_axi_rdata;
  logic [1:0]                 m_axi_rresp;
  logic                       m_axi_rlast;
  logic                       m_axi_rvalid;
  logic                       m_axi_rready;

  logic                       msix_req;
  logic [4:0]                 msix_vector;
  logic                       msix_ack;

  task automatic init_master_side();
    s_axis_opq_tdata  <= '0;
    s_axis_opq_tvalid <= 1'b0;
    s_axis_opq_tlast  <= 1'b0;
    s_axis_opq_tuser  <= 2'b00;
    s_axil_awaddr     <= '0;
    s_axil_awvalid    <= 1'b0;
    s_axil_wdata      <= '0;
    s_axil_wstrb      <= 4'h0;
    s_axil_wvalid     <= 1'b0;
    s_axil_bready     <= 1'b0;
    s_axil_araddr     <= '0;
    s_axil_arvalid    <= 1'b0;
    s_axil_rready     <= 1'b0;
    msix_ack          <= 1'b0;
  endtask

  task automatic init_completer_side();
    m_axi_awready <= 1'b0;
    m_axi_wready  <= 1'b0;
    m_axi_bid     <= '0;
    m_axi_bresp   <= 2'b00;
    m_axi_bvalid  <= 1'b0;
    m_axi_arready <= 1'b0;
    m_axi_rid     <= '0;
    m_axi_rdata   <= '0;
    m_axi_rresp   <= 2'b00;
    m_axi_rlast   <= 1'b0;
    m_axi_rvalid  <= 1'b0;
  endtask
endinterface

`endif
