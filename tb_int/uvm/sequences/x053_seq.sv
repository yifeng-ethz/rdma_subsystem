`ifndef RDMA_SUBSYSTEM_SEQ_X053_SV
`define RDMA_SUBSYSTEM_SEQ_X053_SV

class seq_x053 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x053)

  function new(string name = "seq_x053");
    super.new(name);
    set_case_id("X053");
  endfunction
endclass

`endif
