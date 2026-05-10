`ifndef RDMA_SUBSYSTEM_SEQ_B112_SV
`define RDMA_SUBSYSTEM_SEQ_B112_SV

class seq_b112 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b112)

  function new(string name = "seq_b112");
    super.new(name);
    set_case_id("B112");
  endfunction
endclass

`endif
