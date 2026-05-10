`ifndef RDMA_SUBSYSTEM_SEQ_P112_SV
`define RDMA_SUBSYSTEM_SEQ_P112_SV

class seq_p112 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p112)

  function new(string name = "seq_p112");
    super.new(name);
    set_case_id("P112");
  endfunction
endclass

`endif
