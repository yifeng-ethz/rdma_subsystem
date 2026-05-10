`ifndef RDMA_SUBSYSTEM_SEQ_B067_SV
`define RDMA_SUBSYSTEM_SEQ_B067_SV

class seq_b067 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b067)

  function new(string name = "seq_b067");
    super.new(name);
    set_case_id("B067");
  endfunction
endclass

`endif
