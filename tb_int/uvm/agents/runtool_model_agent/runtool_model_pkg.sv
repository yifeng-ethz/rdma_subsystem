`ifndef RUNTOOL_MODEL_PKG_SV
`define RUNTOOL_MODEL_PKG_SV

package runtool_model_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import subsystem_case_pkg::*;
  import host_axi_completer_pkg::*;
  import opq_source_pkg::*;

  localparam bit [7:0] CSR_UID_CONST               = 8'h00;
  localparam bit [7:0] CSR_META_CONST              = 8'h04;
  localparam bit [7:0] CSR_CTRL_CONST              = 8'h08;
  localparam bit [7:0] CSR_STATUS_CONST            = 8'h0c;
  localparam bit [7:0] CSR_RQ_BASE_LO_CONST        = 8'h10;
  localparam bit [7:0] CSR_RQ_BASE_HI_CONST        = 8'h14;
  localparam bit [7:0] CSR_RQ_DEPTH_CONST          = 8'h18;
  localparam bit [7:0] CSR_RQ_TAIL_DBL_CONST       = 8'h1c;
  localparam bit [7:0] CSR_CQ_BASE_LO_CONST        = 8'h20;
  localparam bit [7:0] CSR_CQ_BASE_HI_CONST        = 8'h24;
  localparam bit [7:0] CSR_CQ_DEPTH_CONST          = 8'h28;
  localparam bit [7:0] CSR_CQ_TAIL_CONST           = 8'h2c;
  localparam bit [7:0] CSR_CQ_HEAD_DBL_CONST       = 8'h30;
  localparam bit [7:0] CSR_CNT_RQE_CONSUMED_CONST  = 8'h34;
  localparam bit [7:0] CSR_CNT_CQE_POSTED_CONST    = 8'h38;
  localparam bit [7:0] CSR_CNT_BYTES_WRITTEN_CONST = 8'h3c;
  localparam bit [7:0] CSR_CNT_OPQ_INPUT_W_CONST   = 8'h40;
  localparam bit [7:0] CSR_CNT_HALT_CONST          = 8'h44;
  localparam bit [7:0] CSR_CNT_EOE_OBSERVED_CONST  = 8'h48;
  // Gen3 x8 PCIe APP bandwidth is 256 bits at 250 MHz = 8 GB/s.
  // A 10 ms host RQ replenish jitter therefore needs 80,000,000 bytes,
  // rounded to the next power of two: 128 MiB aggregate posted rxbuffer.
  // Do not require one RQE to cover this full budget. Model SGL as at most two
  // 2 MiB huge-page segments per RQE; many posted RQEs cover the aggregate.
  localparam bit [63:0] RXBUFFER_FULL_BYTES_CONST       = 64'h0000_0000_0800_0000;
  localparam bit [63:0] RXBUFFER_RQE_BYTES_CONST        = 64'h0000_0000_0020_0000;
  localparam bit [63:0] RXBUFFER_SGL_SEG_BYTES_CONST    = 64'h0000_0000_0020_0000;
  localparam bit [63:0] RXBUFFER_RQE_STRIDE_BYTES_CONST = 64'h0000_0000_0080_0000;

  class runtool_model_cfg extends uvm_object;
    `uvm_object_utils(runtool_model_cfg)

    virtual rdma_subsystem_if vif;
    host_sparse_mem mem;
    opq_source_agent opq;

    function new(string name = "runtool_model_cfg");
      super.new(name);
    endfunction
  endclass

  class runtool_model_agent extends uvm_component;
    `uvm_component_utils(runtool_model_agent)

    runtool_model_cfg cfg;
    uvm_analysis_port #(runtool_state_e) state_ap;
    uvm_analysis_port #(subsystem_cqe_t) cqe_ap;
    runtool_state_e state;
    bit [63:0] rq_base;
    bit [63:0] cq_base;
    int unsigned cq_head;
    int unsigned last_cq_tail;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      state_ap = new("state_ap", this);
      cqe_ap = new("cqe_ap", this);
      state = RUN_IDLE;
      rq_base = 64'h0000_1000_0000_0000;
      cq_base = 64'h0000_2000_0000_0000;
      cq_head = 0;
      last_cq_tail = 0;
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(runtool_model_cfg)::get(this, "", "cfg", cfg))
        `uvm_fatal("RTOOLCFG", "Missing runtool_model_cfg")
    endfunction

    task set_state(input runtool_state_e next_state);
      state = next_state;
      state_ap.write(state);
      @(posedge cfg.vif.clk);
    endtask

    task axil_write(input bit [7:0] addr,
                    input bit [31:0] data,
                    input bit [3:0] strb = 4'hf);
      cfg.vif.s_axil_awaddr <= addr;
      cfg.vif.s_axil_wdata <= data;
      cfg.vif.s_axil_wstrb <= strb;
      cfg.vif.s_axil_awvalid <= 1'b1;
      cfg.vif.s_axil_wvalid <= 1'b1;
      cfg.vif.s_axil_bready <= 1'b1;
      while (!cfg.vif.s_axil_awready)
        @(posedge cfg.vif.clk);
      @(posedge cfg.vif.clk);
      cfg.vif.s_axil_awvalid <= 1'b0;
      while (!cfg.vif.s_axil_wready)
        @(posedge cfg.vif.clk);
      @(posedge cfg.vif.clk);
      cfg.vif.s_axil_wvalid <= 1'b0;
      while (!cfg.vif.s_axil_bvalid)
        @(posedge cfg.vif.clk);
      if (cfg.vif.s_axil_bresp != 2'b00)
        `uvm_error("AXIL", $sformatf("AXI-Lite write addr=0x%02h bresp=%0d", addr, cfg.vif.s_axil_bresp))
      @(posedge cfg.vif.clk);
      cfg.vif.s_axil_bready <= 1'b0;
    endtask

    task axil_read(input bit [7:0] addr,
                   output bit [31:0] data);
      cfg.vif.s_axil_araddr <= addr;
      cfg.vif.s_axil_arvalid <= 1'b1;
      cfg.vif.s_axil_rready <= 1'b1;
      while (!cfg.vif.s_axil_arready)
        @(posedge cfg.vif.clk);
      @(posedge cfg.vif.clk);
      cfg.vif.s_axil_arvalid <= 1'b0;
      while (!cfg.vif.s_axil_rvalid)
        @(posedge cfg.vif.clk);
      data = cfg.vif.s_axil_rdata;
      if (cfg.vif.s_axil_rresp != 2'b00)
        `uvm_error("AXIL", $sformatf("AXI-Lite read addr=0x%02h rresp=%0d", addr, cfg.vif.s_axil_rresp))
      @(posedge cfg.vif.clk);
      cfg.vif.s_axil_rready <= 1'b0;
    endtask

    function bit [511:0] make_rqe(input subsystem_case_cfg case_cfg,
                                  input int unsigned rqe_id);
      bit [511:0] rqe;
      bit [63:0] seg0_addr;
      bit [63:0] seg1_addr;
      bit [63:0] seg0_span;
      bit [63:0] seg1_span;
      rqe = '0;
      seg0_addr = 64'h0000_4000_0000_0000
                  + (longint'(rqe_id) * RXBUFFER_RQE_STRIDE_BYTES_CONST)
                  + (longint'(case_cfg.case_num) << 12);
      seg1_addr = seg0_addr + RXBUFFER_SGL_SEG_BYTES_CONST;
      seg0_span = case_cfg.seg1_used ? RXBUFFER_SGL_SEG_BYTES_CONST : RXBUFFER_RQE_BYTES_CONST;
      seg1_span = case_cfg.seg1_used ? RXBUFFER_SGL_SEG_BYTES_CONST : 64'h0;
      if (case_cfg.force_align_error)
        seg0_addr[3:0] = 4'h4;
      if (case_cfg.force_malformed_rqe)
        seg0_span = 64'h0;
      rqe[63:0] = seg0_addr;
      rqe[127:64] = seg0_span;
      rqe[191:128] = seg1_addr;
      rqe[255:192] = seg1_span;
      rqe[319:256] = {32'h0, rqe_id[15:0], case_cfg.force_malformed_rqe ? 16'h0 : 16'h0001};
      rqe[383:320] = 64'h5255_4e54_4f4f_4c00 | rqe_id;
      rqe[447:384] = 64'h5351_455f_494e_5400 | case_cfg.case_num;
      rqe[511:448] = 64'h0000_0000_0000_0000;
      return rqe;
    endfunction

    function subsystem_cqe_t read_cqe(input longint unsigned addr);
      bit [511:0] raw;
      subsystem_cqe_t cqe;
      raw = cfg.mem.read_wqe512(addr);
      cqe.bytes_written_total = raw[63:0];
      cqe.seg0_bytes_written = raw[95:64];
      cqe.seg1_bytes_written = raw[127:96];
      cqe.status = raw[143:128];
      cqe.rqe_id = raw[159:144];
      cqe.flags = raw[191:160];
      cqe.event_count = raw[255:192];
      cqe.first_event_ts = raw[319:256];
      cqe.last_event_ts = raw[383:320];
      cqe.opq_drop_snapshot = raw[447:384];
      cqe.retire_seq = raw[511:448];
      return cqe;
    endfunction

    task program_rings(input subsystem_case_cfg case_cfg);
      axil_write(CSR_CTRL_CONST, 32'h0000_0002);
      axil_write(CSR_RQ_BASE_LO_CONST, rq_base[31:0]);
      axil_write(CSR_RQ_BASE_HI_CONST, rq_base[63:32]);
      axil_write(CSR_RQ_DEPTH_CONST, case_cfg.rq_depth[31:0]);
      axil_write(CSR_CQ_BASE_LO_CONST, cq_base[31:0]);
      axil_write(CSR_CQ_BASE_HI_CONST, cq_base[63:32]);
      axil_write(CSR_CQ_DEPTH_CONST, case_cfg.cq_depth[31:0]);
    endtask

    task post_rqes(input subsystem_case_cfg case_cfg,
                   input int unsigned count);
      bit [511:0] rqe;
      for (int unsigned idx = 0; idx < count; idx++) begin
        rqe = make_rqe(case_cfg, idx);
        cfg.mem.write_wqe512(rq_base + (longint'(idx) << 6), rqe);
      end
      axil_write(CSR_RQ_TAIL_DBL_CONST, count[31:0]);
    endtask

    task poll_cq(input subsystem_case_cfg case_cfg,
                 input int unsigned expected_count,
                 output int unsigned observed_count);
      bit [31:0] tail_data;
      int unsigned timeout;
      subsystem_cqe_t cqe;
      observed_count = 0;
      timeout = 20000 + expected_count * 5000;
      while (timeout > 0 && observed_count < expected_count) begin
        axil_read(CSR_CQ_TAIL_CONST, tail_data);
        while (last_cq_tail[15:0] != tail_data[15:0] && observed_count < expected_count) begin
          repeat (2) @(posedge cfg.vif.clk);
          cqe = read_cqe(cq_base + (longint'(last_cq_tail) << 6));
          cqe_ap.write(cqe);
          last_cq_tail = (last_cq_tail + 1) % case_cfg.cq_depth;
          observed_count++;
          cq_head = last_cq_tail;
          if (!case_cfg.cq_credit_stall || observed_count == expected_count)
            axil_write(CSR_CQ_HEAD_DBL_CONST, cq_head[31:0]);
        end
        if (observed_count < expected_count)
          repeat (case_cfg.poll_cycles) @(posedge cfg.vif.clk);
        timeout--;
      end
      if (observed_count != expected_count)
        `uvm_fatal("CQTIMEOUT", $sformatf("%s observed %0d/%0d CQEs",
                                          case_cfg.case_id, observed_count, expected_count))
    endtask

    task execute_case(input subsystem_case_cfg case_cfg,
                      output int unsigned observed_txn);
      int unsigned rqe_count;
      observed_txn = 0;
      rqe_count = case_cfg.actual_txn_count;
      set_state(RUN_PREPARING);
      program_rings(case_cfg);
      if (case_cfg.inject_bresp_error)
        ; // The host agent records injected responses; final error policy is DUT-owned.
      if (!case_cfg.idle_only)
        post_rqes(case_cfg, rqe_count);
      if (case_cfg.ctrl_halt_reenable)
        axil_write(CSR_CTRL_CONST, 32'h0000_0005);
      else
        axil_write(CSR_CTRL_CONST, 32'h0000_0001);
      set_state(RUN_RUNNING);
      if (case_cfg.ctrl_halt_reenable) begin
        repeat (case_cfg.poll_cycles) @(posedge cfg.vif.clk);
        axil_write(CSR_CTRL_CONST, 32'h0000_0001);
      end
      if (!case_cfg.idle_only) begin
        int unsigned one_observed;
        repeat (64) @(posedge cfg.vif.clk);
        for (int unsigned idx = 0; idx < rqe_count; idx++) begin
          cfg.opq.enqueue_frame(case_cfg.frame_words, case_cfg.opq_gap_cycles, idx + case_cfg.case_num);
          repeat (case_cfg.opq_gap_cycles + case_cfg.frame_words + 8) @(posedge cfg.vif.clk);
          poll_cq(case_cfg, 1, one_observed);
          observed_txn += one_observed;
        end
      end else begin
        repeat (64) @(posedge cfg.vif.clk);
        observed_txn = 0;
      end
      if (case_cfg.inject_reset) begin
        cfg.vif.reset_n <= 1'b0;
        repeat (4) @(posedge cfg.vif.clk);
        cfg.vif.reset_n <= 1'b1;
        repeat (8) @(posedge cfg.vif.clk);
      end
      set_state(RUN_STOPPING);
      axil_write(CSR_CTRL_CONST, 32'h0000_0000);
      repeat (case_cfg.poll_cycles) @(posedge cfg.vif.clk);
      set_state(RUN_STOPPED);
    endtask
  endclass
endpackage

`endif
