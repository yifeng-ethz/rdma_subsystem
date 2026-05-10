`ifndef RDMA_SUBSYSTEM_SEQ_X099_SV
`define RDMA_SUBSYSTEM_SEQ_X099_SV

class seq_x099 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x099)

  function new(string name = "seq_x099");
    super.new(name);
    set_case_id("X099");
  endfunction
endclass

`endif
