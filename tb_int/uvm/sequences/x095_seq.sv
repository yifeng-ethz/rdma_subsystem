`ifndef RDMA_SUBSYSTEM_SEQ_X095_SV
`define RDMA_SUBSYSTEM_SEQ_X095_SV

class seq_x095 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x095)

  function new(string name = "seq_x095");
    super.new(name);
    set_case_id("X095");
  endfunction
endclass

`endif
