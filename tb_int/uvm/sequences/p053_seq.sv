`ifndef RDMA_SUBSYSTEM_SEQ_P053_SV
`define RDMA_SUBSYSTEM_SEQ_P053_SV

class seq_p053 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p053)

  function new(string name = "seq_p053");
    super.new(name);
    set_case_id("P053");
  endfunction
endclass

`endif
