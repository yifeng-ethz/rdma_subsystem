`ifndef RDMA_SUBSYSTEM_SEQ_B108_SV
`define RDMA_SUBSYSTEM_SEQ_B108_SV

class seq_b108 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b108)

  function new(string name = "seq_b108");
    super.new(name);
    set_case_id("B108");
  endfunction
endclass

`endif
