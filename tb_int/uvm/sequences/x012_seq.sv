`ifndef RDMA_SUBSYSTEM_SEQ_X012_SV
`define RDMA_SUBSYSTEM_SEQ_X012_SV

class seq_x012 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x012)

  function new(string name = "seq_x012");
    super.new(name);
    set_case_id("X012");
  endfunction
endclass

`endif
