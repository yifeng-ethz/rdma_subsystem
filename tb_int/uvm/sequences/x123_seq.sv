`ifndef RDMA_SUBSYSTEM_SEQ_X123_SV
`define RDMA_SUBSYSTEM_SEQ_X123_SV

class seq_x123 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x123)

  function new(string name = "seq_x123");
    super.new(name);
    set_case_id("X123");
  endfunction
endclass

`endif
