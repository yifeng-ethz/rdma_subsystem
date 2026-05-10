`ifndef RDMA_SUBSYSTEM_SEQ_X045_SV
`define RDMA_SUBSYSTEM_SEQ_X045_SV

class seq_x045 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x045)

  function new(string name = "seq_x045");
    super.new(name);
    set_case_id("X045");
  endfunction
endclass

`endif
