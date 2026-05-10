`ifndef RDMA_SUBSYSTEM_SEQ_E033_SV
`define RDMA_SUBSYSTEM_SEQ_E033_SV

class seq_e033 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e033)

  function new(string name = "seq_e033");
    super.new(name);
    set_case_id("E033");
  endfunction
endclass

`endif
