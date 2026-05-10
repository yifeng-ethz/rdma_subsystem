`ifndef RDMA_SUBSYSTEM_SEQ_P013_SV
`define RDMA_SUBSYSTEM_SEQ_P013_SV

class seq_p013 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p013)

  function new(string name = "seq_p013");
    super.new(name);
    set_case_id("P013");
  endfunction
endclass

`endif
