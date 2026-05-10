`ifndef RDMA_SUBSYSTEM_SEQ_P101_SV
`define RDMA_SUBSYSTEM_SEQ_P101_SV

class seq_p101 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p101)

  function new(string name = "seq_p101");
    super.new(name);
    set_case_id("P101");
  endfunction
endclass

`endif
