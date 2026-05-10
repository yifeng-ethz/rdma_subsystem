`ifndef RDMA_SUBSYSTEM_SEQ_P068_SV
`define RDMA_SUBSYSTEM_SEQ_P068_SV

class seq_p068 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p068)

  function new(string name = "seq_p068");
    super.new(name);
    set_case_id("P068");
  endfunction
endclass

`endif
