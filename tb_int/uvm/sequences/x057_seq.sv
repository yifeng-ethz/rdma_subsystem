`ifndef RDMA_SUBSYSTEM_SEQ_X057_SV
`define RDMA_SUBSYSTEM_SEQ_X057_SV

class seq_x057 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x057)

  function new(string name = "seq_x057");
    super.new(name);
    set_case_id("X057");
  endfunction
endclass

`endif
