`ifndef RDMA_SUBSYSTEM_SEQ_E052_SV
`define RDMA_SUBSYSTEM_SEQ_E052_SV

class seq_e052 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e052)

  function new(string name = "seq_e052");
    super.new(name);
    set_case_id("E052");
  endfunction
endclass

`endif
