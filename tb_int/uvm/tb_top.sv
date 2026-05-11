`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import subsystem_env_pkg::*;

  localparam int unsigned DMA_DATA_W = 256;
  localparam int unsigned WQE_BUS_W = 512;

  logic clk;
  bit tb_int_diag;
  rdma_subsystem_if #(.DMA_DATA_W(DMA_DATA_W)) dut_if(.clk(clk));

  initial begin
    clk = 1'b0;
    forever #2 clk = ~clk;
  end

  rdma_subsystem_top #(
    .DMA_DATA_W(DMA_DATA_W),
    .WQE_BUS_W(WQE_BUS_W),
    .DEBUG_LEVEL(`DEBUG_LEVEL)
  ) dut (
    .clk(dut_if.clk),
    .reset_n(dut_if.reset_n),
    .s_axis_opq_tdata(dut_if.s_axis_opq_tdata),
    .s_axis_opq_tvalid(dut_if.s_axis_opq_tvalid),
    .s_axis_opq_tready(dut_if.s_axis_opq_tready),
    .s_axis_opq_tlast(dut_if.s_axis_opq_tlast),
    .s_axis_opq_tuser(dut_if.s_axis_opq_tuser),
    .s_axil_awaddr(dut_if.s_axil_awaddr),
    .s_axil_awvalid(dut_if.s_axil_awvalid),
    .s_axil_awready(dut_if.s_axil_awready),
    .s_axil_wdata(dut_if.s_axil_wdata),
    .s_axil_wstrb(dut_if.s_axil_wstrb),
    .s_axil_wvalid(dut_if.s_axil_wvalid),
    .s_axil_wready(dut_if.s_axil_wready),
    .s_axil_bresp(dut_if.s_axil_bresp),
    .s_axil_bvalid(dut_if.s_axil_bvalid),
    .s_axil_bready(dut_if.s_axil_bready),
    .s_axil_araddr(dut_if.s_axil_araddr),
    .s_axil_arvalid(dut_if.s_axil_arvalid),
    .s_axil_arready(dut_if.s_axil_arready),
    .s_axil_rdata(dut_if.s_axil_rdata),
    .s_axil_rresp(dut_if.s_axil_rresp),
    .s_axil_rvalid(dut_if.s_axil_rvalid),
    .s_axil_rready(dut_if.s_axil_rready),
    .m_axi_awid(dut_if.m_axi_awid),
    .m_axi_awaddr(dut_if.m_axi_awaddr),
    .m_axi_awlen(dut_if.m_axi_awlen),
    .m_axi_awsize(dut_if.m_axi_awsize),
    .m_axi_awburst(dut_if.m_axi_awburst),
    .m_axi_awvalid(dut_if.m_axi_awvalid),
    .m_axi_awready(dut_if.m_axi_awready),
    .m_axi_wdata(dut_if.m_axi_wdata),
    .m_axi_wstrb(dut_if.m_axi_wstrb),
    .m_axi_wlast(dut_if.m_axi_wlast),
    .m_axi_wvalid(dut_if.m_axi_wvalid),
    .m_axi_wready(dut_if.m_axi_wready),
    .m_axi_bid(dut_if.m_axi_bid),
    .m_axi_bresp(dut_if.m_axi_bresp),
    .m_axi_bvalid(dut_if.m_axi_bvalid),
    .m_axi_bready(dut_if.m_axi_bready),
    .m_axi_arid(dut_if.m_axi_arid),
    .m_axi_araddr(dut_if.m_axi_araddr),
    .m_axi_arlen(dut_if.m_axi_arlen),
    .m_axi_arsize(dut_if.m_axi_arsize),
    .m_axi_arburst(dut_if.m_axi_arburst),
    .m_axi_arvalid(dut_if.m_axi_arvalid),
    .m_axi_arready(dut_if.m_axi_arready),
    .m_axi_rid(dut_if.m_axi_rid),
    .m_axi_rdata(dut_if.m_axi_rdata),
    .m_axi_rresp(dut_if.m_axi_rresp),
    .m_axi_rlast(dut_if.m_axi_rlast),
    .m_axi_rvalid(dut_if.m_axi_rvalid),
    .m_axi_rready(dut_if.m_axi_rready),
    .msix_req(dut_if.msix_req),
    .msix_vector(dut_if.msix_vector),
    .msix_ack(dut_if.msix_ack)
  );

  initial begin
    tb_int_diag = $test$plusargs("TB_INT_DIAG");
  end

  always_ff @(posedge clk) begin
    if (tb_int_diag && dut_if.reset_n) begin
      if (dut.rq_axi_arvalid && dut.rq_axi_arready) begin
        $display("TB_INT_DIAG RQ_AR t=%0t addr=0x%016h len=%0d size=%0d",
                 $time, dut.rq_axi_araddr, dut.rq_axi_arlen, dut.rq_axi_arsize);
      end
      if (dut.m_axi_arvalid && dut.m_axi_arready) begin
        $display("TB_INT_DIAG HOST_AR t=%0t addr=0x%016h len=%0d size=%0d",
                 $time, dut.m_axi_araddr, dut.m_axi_arlen, dut.m_axi_arsize);
      end
      if (dut.m_axi_rvalid && dut.m_axi_rready) begin
        $display("TB_INT_DIAG HOST_R t=%0t last=%0b xbar_idx=%0d word1=0x%016h word0=0x%016h",
                 $time, dut.m_axi_rlast, dut.axi_xbar_i.read.beat_index,
                 dut.m_axi_rdata[127:64], dut.m_axi_rdata[63:0]);
      end
      if (dut.rq_axi_rvalid && dut.rq_axi_rready) begin
        $display("TB_INT_DIAG RQ_R t=%0t last=%0b word4=0x%016h word0=0x%016h",
                 $time, dut.rq_axi_rlast, dut.rq_axi_rdata[319:256],
                 dut.rq_axi_rdata[63:0]);
      end
      if (dut.rqe_tvalid && dut.rqe_tready) begin
        $display("TB_INT_DIAG RQE_ACCEPT t=%0t tlast=%0b id=%0d opcode_id=0x%016h seg0_addr=0x%016h seg0_span=0x%016h",
                 $time, dut.rqe_tlast, dut.rqe_tuser, dut.rqe_tdata[319:256],
                 dut.rqe_tdata[63:0], dut.rqe_tdata[127:64]);
      end
      if (dut.dma_job_req) begin
        $display("TB_INT_DIAG DMA_JOB t=%0t id=%0d opcode=0x%04h seg0=0x%016h span0=%0d",
                 $time, dut.dma_job_rqe_id, dut.dma_job_opcode,
                 dut.dma_job_seg0_addr, dut.dma_job_seg0_span);
      end
      if (dut.cqe_tvalid && dut.cqe_tready) begin
        $display("TB_INT_DIAG CQE_STREAM t=%0t id=%0d status=0x%04h bytes=%0d",
                 $time, dut.cqe_tuser, dut.cqe_tdata[143:128], dut.cqe_tdata[63:0]);
      end
    end
  end

  initial begin
    uvm_config_db#(virtual rdma_subsystem_if)::set(null, "*", "vif", dut_if);
    run_test();
  end
endmodule
