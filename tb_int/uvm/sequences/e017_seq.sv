`ifndef RDMA_SUBSYSTEM_SEQ_E017_SV
`define RDMA_SUBSYSTEM_SEQ_E017_SV

class seq_e017 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e017)

  function new(string name = "seq_e017");
    super.new(name);
    set_case_id("E017");
  endfunction
endclass

`endif
