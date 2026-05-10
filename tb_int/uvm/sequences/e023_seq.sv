`ifndef RDMA_SUBSYSTEM_SEQ_E023_SV
`define RDMA_SUBSYSTEM_SEQ_E023_SV

class seq_e023 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e023)

  function new(string name = "seq_e023");
    super.new(name);
    set_case_id("E023");
  endfunction
endclass

`endif
