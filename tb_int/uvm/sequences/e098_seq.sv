`ifndef RDMA_SUBSYSTEM_SEQ_E098_SV
`define RDMA_SUBSYSTEM_SEQ_E098_SV

class seq_e098 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e098)

  function new(string name = "seq_e098");
    super.new(name);
    set_case_id("E098");
  endfunction
endclass

`endif
