`ifndef RDMA_SUBSYSTEM_SEQ_X105_SV
`define RDMA_SUBSYSTEM_SEQ_X105_SV

class seq_x105 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x105)

  function new(string name = "seq_x105");
    super.new(name);
    set_case_id("X105");
  endfunction
endclass

`endif
