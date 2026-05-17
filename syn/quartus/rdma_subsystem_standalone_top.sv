// File name: rdma_subsystem_standalone_top.sv
// Author  : Yifeng Wang (yifenwan@phys.ethz.ch)
// Version : 26.1.0
// Date    : 20260510
// Change  : standalone synthesis harness for rdma_subsystem sign-off

`default_nettype none

module rdma_subsystem_standalone_top #(
    parameter int unsigned DMA_DATA_W = 256,
    parameter int unsigned WQE_BUS_W  = 512
) (
    input  wire logic   clk,
    input  wire logic   reset_n,
    output logic [31:0] signature
);

    logic [31:0]                stim_counter;
    logic [35:0]                s_axis_opq_tdata;
    logic                       s_axis_opq_tvalid;
    logic                       s_axis_opq_tready;
    logic                       s_axis_opq_tlast;
    logic [1:0]                 s_axis_opq_tuser;
    logic                       pcie_posted_write_credit_valid;
    logic [31:0]                pcie_posted_write_credit_words;
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

    always_ff @(posedge clk or negedge reset_n) begin : harness_counter
        if (!reset_n) begin
            stim_counter <= 32'h0000_0000;
        end else begin
            stim_counter <= stim_counter + 32'd1;
        end
    end

    always_comb begin : csr_stimulus
        s_axil_awaddr  = 8'h08;
        s_axil_wdata   = 32'h0000_0001;
        s_axil_araddr  = {2'b00, stim_counter[7:2]};

        unique case (stim_counter[7:4])
            4'h0: begin
                s_axil_awaddr = 8'h10;
                s_axil_wdata  = {16'h0000, stim_counter[15:0]};
            end
            4'h1: begin
                s_axil_awaddr = 8'h14;
                s_axil_wdata  = 32'h0000_0100;
            end
            4'h2: begin
                s_axil_awaddr = 8'h18;
                s_axil_wdata  = 32'h0000_0008;
            end
            4'h3: begin
                s_axil_awaddr = 8'h20;
                s_axil_wdata  = {16'h0001, stim_counter[15:0]};
            end
            4'h4: begin
                s_axil_awaddr = 8'h24;
                s_axil_wdata  = 32'h0000_0200;
            end
            4'h5: begin
                s_axil_awaddr = 8'h28;
                s_axil_wdata  = 32'h0000_0008;
            end
            4'h6: begin
                s_axil_awaddr = 8'h1c;
                s_axil_wdata  = {16'h0000, stim_counter[15:0]};
            end
            4'h7: begin
                s_axil_awaddr = 8'h30;
                s_axil_wdata  = {16'h0000, stim_counter[15:0]};
            end
            default: begin
                s_axil_awaddr = 8'h08;
                s_axil_wdata  = 32'h0000_0001;
            end
        endcase
    end

    assign s_axis_opq_tdata  = {stim_counter[3:0], stim_counter};
    assign s_axis_opq_tvalid = stim_counter[0] || stim_counter[4];
    assign s_axis_opq_tlast  = (stim_counter[6:0] == 7'h7f);
    assign s_axis_opq_tuser  = {1'b0, (stim_counter[4:0] == 5'h00)};
    assign pcie_posted_write_credit_valid = 1'b1;
    assign pcie_posted_write_credit_words = 32'hffff_ffff;

    assign s_axil_awvalid = (stim_counter[2:0] == 3'b001);
    assign s_axil_wstrb   = 4'hf;
    assign s_axil_wvalid  = (stim_counter[2:0] == 3'b001);
    assign s_axil_bready  = 1'b1;
    assign s_axil_arvalid = (stim_counter[3:0] == 4'b1010);
    assign s_axil_rready  = 1'b1;

    assign m_axi_awready = stim_counter[1] || stim_counter[5];
    assign m_axi_wready  = stim_counter[2] || stim_counter[6];
    assign m_axi_bid     = m_axi_awid ^ stim_counter[3:0];
    assign m_axi_bresp   = 2'b00;
    assign m_axi_bvalid  = m_axi_wvalid && (stim_counter[4] || m_axi_wlast);
    assign m_axi_arready = stim_counter[1] || stim_counter[3];
    assign m_axi_rid     = m_axi_arid ^ stim_counter[7:4];
    assign m_axi_rdata   = {8{stim_counter}};
    assign m_axi_rresp   = 2'b00;
    assign m_axi_rlast   = stim_counter[0];
    assign m_axi_rvalid  = m_axi_arvalid || stim_counter[2];
    assign msix_ack      = stim_counter[5];

    rdma_subsystem_top #(
        .DMA_DATA_W   (DMA_DATA_W),
        .WQE_BUS_W    (WQE_BUS_W),
        .DEBUG_LEVEL  (0),
        .VERSION_MAJOR(26),
        .VERSION_MINOR(1),
        .VERSION_PATCH(0),
        .BUILD        (510),
        .VERSION_DATE (32'd20260510),
        .VERSION_GIT  (32'h0b66_a91b),
        .INSTANCE_ID  (32'h0000_0000)
    ) dut_i (
        .clk               (clk),
        .reset_n           (reset_n),
        .s_axis_opq_tdata  (s_axis_opq_tdata),
        .s_axis_opq_tvalid (s_axis_opq_tvalid),
        .s_axis_opq_tready (s_axis_opq_tready),
        .s_axis_opq_tlast  (s_axis_opq_tlast),
        .s_axis_opq_tuser  (s_axis_opq_tuser),
        .pcie_posted_write_credit_valid(pcie_posted_write_credit_valid),
        .pcie_posted_write_credit_words(pcie_posted_write_credit_words),
        .s_axil_awaddr     (s_axil_awaddr),
        .s_axil_awvalid    (s_axil_awvalid),
        .s_axil_awready    (s_axil_awready),
        .s_axil_wdata      (s_axil_wdata),
        .s_axil_wstrb      (s_axil_wstrb),
        .s_axil_wvalid     (s_axil_wvalid),
        .s_axil_wready     (s_axil_wready),
        .s_axil_bresp      (s_axil_bresp),
        .s_axil_bvalid     (s_axil_bvalid),
        .s_axil_bready     (s_axil_bready),
        .s_axil_araddr     (s_axil_araddr),
        .s_axil_arvalid    (s_axil_arvalid),
        .s_axil_arready    (s_axil_arready),
        .s_axil_rdata      (s_axil_rdata),
        .s_axil_rresp      (s_axil_rresp),
        .s_axil_rvalid     (s_axil_rvalid),
        .s_axil_rready     (s_axil_rready),
        .m_axi_awid        (m_axi_awid),
        .m_axi_awaddr      (m_axi_awaddr),
        .m_axi_awlen       (m_axi_awlen),
        .m_axi_awsize      (m_axi_awsize),
        .m_axi_awburst     (m_axi_awburst),
        .m_axi_awvalid     (m_axi_awvalid),
        .m_axi_awready     (m_axi_awready),
        .m_axi_wdata       (m_axi_wdata),
        .m_axi_wstrb       (m_axi_wstrb),
        .m_axi_wlast       (m_axi_wlast),
        .m_axi_wvalid      (m_axi_wvalid),
        .m_axi_wready      (m_axi_wready),
        .m_axi_bid         (m_axi_bid),
        .m_axi_bresp       (m_axi_bresp),
        .m_axi_bvalid      (m_axi_bvalid),
        .m_axi_bready      (m_axi_bready),
        .m_axi_arid        (m_axi_arid),
        .m_axi_araddr      (m_axi_araddr),
        .m_axi_arlen       (m_axi_arlen),
        .m_axi_arsize      (m_axi_arsize),
        .m_axi_arburst     (m_axi_arburst),
        .m_axi_arvalid     (m_axi_arvalid),
        .m_axi_arready     (m_axi_arready),
        .m_axi_rid         (m_axi_rid),
        .m_axi_rdata       (m_axi_rdata),
        .m_axi_rresp       (m_axi_rresp),
        .m_axi_rlast       (m_axi_rlast),
        .m_axi_rvalid      (m_axi_rvalid),
        .m_axi_rready      (m_axi_rready),
        .msix_req          (msix_req),
        .msix_vector       (msix_vector),
        .msix_ack          (msix_ack)
    );

    assign signature = {
        ^s_axil_rdata,
        ^m_axi_awaddr,
        ^m_axi_wdata,
        ^m_axi_araddr,
        ^m_axi_rdata,
        ^m_axi_wstrb,
        ^m_axi_awlen,
        ^m_axi_arlen,
        ^s_axil_bresp,
        ^s_axil_rresp,
        s_axis_opq_tready,
        s_axil_awready,
        s_axil_wready,
        s_axil_bvalid,
        s_axil_arready,
        s_axil_rvalid,
        m_axi_awvalid,
        m_axi_wvalid,
        m_axi_bready,
        m_axi_arvalid,
        m_axi_rready,
        msix_req,
        ^msix_vector
    };

endmodule

`default_nettype wire
