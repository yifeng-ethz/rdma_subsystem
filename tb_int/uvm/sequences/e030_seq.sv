`ifndef RDMA_SUBSYSTEM_SEQ_E030_SV
`define RDMA_SUBSYSTEM_SEQ_E030_SV

class seq_e030 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e030)

  function new(string name = "seq_e030");
    super.new(name);
    set_case_id("E030");
  endfunction
endclass

`endif
