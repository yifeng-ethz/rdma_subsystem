`ifndef RDMA_SUBSYSTEM_SEQ_B101_SV
`define RDMA_SUBSYSTEM_SEQ_B101_SV

class seq_b101 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b101)

  function new(string name = "seq_b101");
    super.new(name);
    set_case_id("B101");
  endfunction
endclass

`endif
