`ifndef RDMA_SUBSYSTEM_SEQ_P018_SV
`define RDMA_SUBSYSTEM_SEQ_P018_SV

class seq_p018 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p018)

  function new(string name = "seq_p018");
    super.new(name);
    set_case_id("P018");
  endfunction
endclass

`endif
