`ifndef RDMA_SUBSYSTEM_SEQ_P009_SV
`define RDMA_SUBSYSTEM_SEQ_P009_SV

class seq_p009 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p009)

  function new(string name = "seq_p009");
    super.new(name);
    set_case_id("P009");
  endfunction
endclass

`endif
