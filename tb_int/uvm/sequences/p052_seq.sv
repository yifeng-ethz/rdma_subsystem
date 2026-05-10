`ifndef RDMA_SUBSYSTEM_SEQ_P052_SV
`define RDMA_SUBSYSTEM_SEQ_P052_SV

class seq_p052 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p052)

  function new(string name = "seq_p052");
    super.new(name);
    set_case_id("P052");
  endfunction
endclass

`endif
