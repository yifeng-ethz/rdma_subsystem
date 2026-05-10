`ifndef RDMA_SUBSYSTEM_SEQ_B114_SV
`define RDMA_SUBSYSTEM_SEQ_B114_SV

class seq_b114 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b114)

  function new(string name = "seq_b114");
    super.new(name);
    set_case_id("B114");
  endfunction
endclass

`endif
