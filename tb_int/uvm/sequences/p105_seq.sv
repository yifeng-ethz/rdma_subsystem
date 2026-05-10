`ifndef RDMA_SUBSYSTEM_SEQ_P105_SV
`define RDMA_SUBSYSTEM_SEQ_P105_SV

class seq_p105 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p105)

  function new(string name = "seq_p105");
    super.new(name);
    set_case_id("P105");
  endfunction
endclass

`endif
