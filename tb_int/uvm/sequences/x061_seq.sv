`ifndef RDMA_SUBSYSTEM_SEQ_X061_SV
`define RDMA_SUBSYSTEM_SEQ_X061_SV

class seq_x061 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x061)

  function new(string name = "seq_x061");
    super.new(name);
    set_case_id("X061");
  endfunction
endclass

`endif
