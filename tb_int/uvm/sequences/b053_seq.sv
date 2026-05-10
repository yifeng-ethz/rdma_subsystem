`ifndef RDMA_SUBSYSTEM_SEQ_B053_SV
`define RDMA_SUBSYSTEM_SEQ_B053_SV

class seq_b053 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b053)

  function new(string name = "seq_b053");
    super.new(name);
    set_case_id("B053");
  endfunction
endclass

`endif
