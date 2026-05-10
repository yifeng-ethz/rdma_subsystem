`ifndef RDMA_SUBSYSTEM_SEQ_X013_SV
`define RDMA_SUBSYSTEM_SEQ_X013_SV

class seq_x013 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x013)

  function new(string name = "seq_x013");
    super.new(name);
    set_case_id("X013");
  endfunction
endclass

`endif
