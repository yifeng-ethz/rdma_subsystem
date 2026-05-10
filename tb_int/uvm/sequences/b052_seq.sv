`ifndef RDMA_SUBSYSTEM_SEQ_B052_SV
`define RDMA_SUBSYSTEM_SEQ_B052_SV

class seq_b052 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b052)

  function new(string name = "seq_b052");
    super.new(name);
    set_case_id("B052");
  endfunction
endclass

`endif
