`ifndef RDMA_SUBSYSTEM_SEQ_E110_SV
`define RDMA_SUBSYSTEM_SEQ_E110_SV

class seq_e110 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e110)

  function new(string name = "seq_e110");
    super.new(name);
    set_case_id("E110");
  endfunction
endclass

`endif
