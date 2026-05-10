`ifndef RDMA_SUBSYSTEM_SEQ_X112_SV
`define RDMA_SUBSYSTEM_SEQ_X112_SV

class seq_x112 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x112)

  function new(string name = "seq_x112");
    super.new(name);
    set_case_id("X112");
  endfunction
endclass

`endif
