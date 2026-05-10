`ifndef RDMA_SUBSYSTEM_SEQ_X025_SV
`define RDMA_SUBSYSTEM_SEQ_X025_SV

class seq_x025 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x025)

  function new(string name = "seq_x025");
    super.new(name);
    set_case_id("X025");
  endfunction
endclass

`endif
