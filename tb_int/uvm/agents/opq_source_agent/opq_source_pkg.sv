`ifndef OPQ_SOURCE_PKG_SV
`define OPQ_SOURCE_PKG_SV

package opq_source_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef struct {
    longint unsigned seq;
    bit [31:0] word;
    bit [3:0] datak;
    bit sop;
    bit eop;
  } opq_word_obs_t;

  class opq_frame_item extends uvm_object;
    `uvm_object_utils(opq_frame_item)

    int unsigned body_words;
    int unsigned gap_cycles;
    int unsigned frame_id;

    function new(string name = "opq_frame_item");
      super.new(name);
      body_words = 4;
      gap_cycles = 0;
      frame_id = 0;
    endfunction
  endclass

  class opq_source_cfg extends uvm_object;
    `uvm_object_utils(opq_source_cfg)

    virtual rdma_subsystem_if vif;
    int unsigned max_ready_wait_cycles;

    function new(string name = "opq_source_cfg");
      super.new(name);
      max_ready_wait_cycles = 10000;
    endfunction
  endclass

  class opq_source_agent extends uvm_component;
    `uvm_component_utils(opq_source_agent)

    opq_source_cfg cfg;
    mailbox #(opq_frame_item) frame_mbox;
    uvm_analysis_port #(opq_word_obs_t) word_ap;
    longint unsigned seq;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      frame_mbox = new();
      word_ap = new("word_ap", this);
      seq = 0;
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(opq_source_cfg)::get(this, "", "cfg", cfg))
        `uvm_fatal("OPQCFG", "Missing opq_source_cfg")
    endfunction

    task enqueue_frame(input int unsigned body_words,
                       input int unsigned gap_cycles,
                       input int unsigned frame_id);
      opq_frame_item item;
      item = opq_frame_item::type_id::create("item");
      item.body_words = body_words;
      item.gap_cycles = gap_cycles;
      item.frame_id = frame_id;
      frame_mbox.put(item);
    endtask

    task drive_word(input bit [31:0] word,
                    input bit [3:0] datak,
                    input bit sop,
                    input bit eop);
      opq_word_obs_t obs;
      int unsigned wait_count;
      cfg.vif.s_axis_opq_tdata <= {datak, word};
      cfg.vif.s_axis_opq_tuser <= {1'b0, sop};
      cfg.vif.s_axis_opq_tlast <= eop;
      cfg.vif.s_axis_opq_tvalid <= 1'b1;
      wait_count = 0;
      while (cfg.vif.reset_n && !cfg.vif.s_axis_opq_tready) begin
        @(posedge cfg.vif.clk);
        wait_count++;
        if (wait_count > cfg.max_ready_wait_cycles)
          `uvm_fatal("OPQREADY", "Timed out waiting for s_axis_opq_tready")
      end
      @(posedge cfg.vif.clk);
      obs.seq = seq++;
      obs.word = word;
      obs.datak = datak;
      obs.sop = sop;
      obs.eop = eop;
      word_ap.write(obs);
      cfg.vif.s_axis_opq_tvalid <= 1'b0;
      cfg.vif.s_axis_opq_tlast <= 1'b0;
      cfg.vif.s_axis_opq_tuser <= 2'b00;
      cfg.vif.s_axis_opq_tdata <= '0;
    endtask

    task drive_frame(opq_frame_item item);
      repeat (item.gap_cycles) @(posedge cfg.vif.clk);
      drive_word(32'h0000_00bc, 4'h1, 1'b1, 1'b0);
      for (int unsigned idx = 0; idx < item.body_words; idx++) begin
        bit [31:0] body;
        body = 32'h4800_0000 ^ {item.frame_id[7:0], idx[7:0], 16'h55aa};
        drive_word(body, 4'h0, 1'b0, 1'b0);
      end
      drive_word(32'h0000_009c, 4'h1, 1'b0, 1'b1);
    endtask

    task run_phase(uvm_phase phase);
      opq_frame_item item;
      cfg.vif.s_axis_opq_tvalid <= 1'b0;
      cfg.vif.s_axis_opq_tlast <= 1'b0;
      cfg.vif.s_axis_opq_tuser <= 2'b00;
      cfg.vif.s_axis_opq_tdata <= '0;
      forever begin
        frame_mbox.get(item);
        while (cfg.vif.reset_n !== 1'b1)
          @(posedge cfg.vif.clk);
        drive_frame(item);
      end
    endtask
  endclass
endpackage

`endif
