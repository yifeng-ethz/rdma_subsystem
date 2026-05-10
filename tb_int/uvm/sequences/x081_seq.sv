`ifndef RDMA_SUBSYSTEM_SEQ_X081_SV
`define RDMA_SUBSYSTEM_SEQ_X081_SV

class seq_x081 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x081)

  function new(string name = "seq_x081");
    super.new(name);
    set_case_id("X081");
  endfunction
endclass

`endif
