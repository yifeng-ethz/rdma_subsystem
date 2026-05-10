`ifndef RDMA_SUBSYSTEM_SEQ_B098_SV
`define RDMA_SUBSYSTEM_SEQ_B098_SV

class seq_b098 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b098)

  function new(string name = "seq_b098");
    super.new(name);
    set_case_id("B098");
  endfunction
endclass

`endif
