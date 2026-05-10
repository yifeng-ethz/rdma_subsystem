`ifndef RDMA_SUBSYSTEM_SEQ_E097_SV
`define RDMA_SUBSYSTEM_SEQ_E097_SV

class seq_e097 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e097)

  function new(string name = "seq_e097");
    super.new(name);
    set_case_id("E097");
  endfunction
endclass

`endif
