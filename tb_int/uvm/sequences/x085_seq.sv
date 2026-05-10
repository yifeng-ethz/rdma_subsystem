`ifndef RDMA_SUBSYSTEM_SEQ_X085_SV
`define RDMA_SUBSYSTEM_SEQ_X085_SV

class seq_x085 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x085)

  function new(string name = "seq_x085");
    super.new(name);
    set_case_id("X085");
  endfunction
endclass

`endif
