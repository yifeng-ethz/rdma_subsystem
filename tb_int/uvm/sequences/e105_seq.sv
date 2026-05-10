`ifndef RDMA_SUBSYSTEM_SEQ_E105_SV
`define RDMA_SUBSYSTEM_SEQ_E105_SV

class seq_e105 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e105)

  function new(string name = "seq_e105");
    super.new(name);
    set_case_id("E105");
  endfunction
endclass

`endif
