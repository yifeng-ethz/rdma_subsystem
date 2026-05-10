`ifndef RDMA_SUBSYSTEM_SEQ_X091_SV
`define RDMA_SUBSYSTEM_SEQ_X091_SV

class seq_x091 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x091)

  function new(string name = "seq_x091");
    super.new(name);
    set_case_id("X091");
  endfunction
endclass

`endif
