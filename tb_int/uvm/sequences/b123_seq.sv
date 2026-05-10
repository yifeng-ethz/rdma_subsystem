`ifndef RDMA_SUBSYSTEM_SEQ_B123_SV
`define RDMA_SUBSYSTEM_SEQ_B123_SV

class seq_b123 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b123)

  function new(string name = "seq_b123");
    super.new(name);
    set_case_id("B123");
  endfunction
endclass

`endif
