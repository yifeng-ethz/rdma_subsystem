`ifndef RDMA_SUBSYSTEM_SEQ_B028_SV
`define RDMA_SUBSYSTEM_SEQ_B028_SV

class seq_b028 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b028)

  function new(string name = "seq_b028");
    super.new(name);
    set_case_id("B028");
  endfunction
endclass

`endif
