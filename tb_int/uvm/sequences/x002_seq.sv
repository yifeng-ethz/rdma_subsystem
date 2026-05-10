`ifndef RDMA_SUBSYSTEM_SEQ_X002_SV
`define RDMA_SUBSYSTEM_SEQ_X002_SV

class seq_x002 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x002)

  function new(string name = "seq_x002");
    super.new(name);
    set_case_id("X002");
  endfunction
endclass

`endif
