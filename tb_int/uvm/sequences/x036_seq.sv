`ifndef RDMA_SUBSYSTEM_SEQ_X036_SV
`define RDMA_SUBSYSTEM_SEQ_X036_SV

class seq_x036 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x036)

  function new(string name = "seq_x036");
    super.new(name);
    set_case_id("X036");
  endfunction
endclass

`endif
