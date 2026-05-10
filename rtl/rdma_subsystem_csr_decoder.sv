// File name: rdma_subsystem_csr_decoder.sv
// Author  : Yifeng Wang (yifenwan@phys.ethz.ch)
// Version : 26.1.0
// Date    : 20260510
// Change  : add BAR1 AXI4-Lite passthrough to rdma_run_manager

`default_nettype none

module rdma_subsystem_csr_decoder (
    input  wire logic        reset_n,

    input  wire logic [7:0]  s_axil_awaddr,
    input  wire logic        s_axil_awvalid,
    output logic             s_axil_awready,
    input  wire logic [31:0] s_axil_wdata,
    input  wire logic [3:0]  s_axil_wstrb,
    input  wire logic        s_axil_wvalid,
    output logic             s_axil_wready,
    output logic [1:0]       s_axil_bresp,
    output logic             s_axil_bvalid,
    input  wire logic        s_axil_bready,
    input  wire logic [7:0]  s_axil_araddr,
    input  wire logic        s_axil_arvalid,
    output logic             s_axil_arready,
    output logic [31:0]      s_axil_rdata,
    output logic [1:0]       s_axil_rresp,
    output logic             s_axil_rvalid,
    input  wire logic        s_axil_rready,

    output logic [7:0]       m_axil_awaddr,
    output logic             m_axil_awvalid,
    input  wire logic        m_axil_awready,
    output logic [31:0]      m_axil_wdata,
    output logic [3:0]       m_axil_wstrb,
    output logic             m_axil_wvalid,
    input  wire logic        m_axil_wready,
    input  wire logic [1:0]  m_axil_bresp,
    input  wire logic        m_axil_bvalid,
    output logic             m_axil_bready,
    output logic [7:0]       m_axil_araddr,
    output logic             m_axil_arvalid,
    input  wire logic        m_axil_arready,
    input  wire logic [31:0] m_axil_rdata,
    input  wire logic [1:0]  m_axil_rresp,
    input  wire logic        m_axil_rvalid,
    output logic             m_axil_rready
);

    assign m_axil_awaddr  = s_axil_awaddr;
    assign m_axil_awvalid = reset_n && s_axil_awvalid;
    assign s_axil_awready = reset_n && m_axil_awready;
    assign m_axil_wdata   = s_axil_wdata;
    assign m_axil_wstrb   = s_axil_wstrb;
    assign m_axil_wvalid  = reset_n && s_axil_wvalid;
    assign s_axil_wready  = reset_n && m_axil_wready;
    assign s_axil_bresp   = reset_n ? m_axil_bresp : 2'b00;
    assign s_axil_bvalid  = reset_n && m_axil_bvalid;
    assign m_axil_bready  = reset_n && s_axil_bready;
    assign m_axil_araddr  = s_axil_araddr;
    assign m_axil_arvalid = reset_n && s_axil_arvalid;
    assign s_axil_arready = reset_n && m_axil_arready;
    assign s_axil_rdata   = reset_n ? m_axil_rdata : 32'h0000_0000;
    assign s_axil_rresp   = reset_n ? m_axil_rresp : 2'b00;
    assign s_axil_rvalid  = reset_n && m_axil_rvalid;
    assign m_axil_rready  = reset_n && s_axil_rready;

endmodule

`default_nettype wire
