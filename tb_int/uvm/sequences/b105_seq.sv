`ifndef RDMA_SUBSYSTEM_SEQ_B105_SV
`define RDMA_SUBSYSTEM_SEQ_B105_SV

class seq_b105 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b105)

  function new(string name = "seq_b105");
    super.new(name);
    set_case_id("B105");
  endfunction
endclass

`endif
