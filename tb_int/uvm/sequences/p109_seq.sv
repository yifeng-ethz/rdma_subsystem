`ifndef RDMA_SUBSYSTEM_SEQ_P109_SV
`define RDMA_SUBSYSTEM_SEQ_P109_SV

class seq_p109 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p109)

  function new(string name = "seq_p109");
    super.new(name);
    set_case_id("P109");
  endfunction
endclass

`endif
