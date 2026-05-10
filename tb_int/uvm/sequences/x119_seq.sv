`ifndef RDMA_SUBSYSTEM_SEQ_X119_SV
`define RDMA_SUBSYSTEM_SEQ_X119_SV

class seq_x119 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x119)

  function new(string name = "seq_x119");
    super.new(name);
    set_case_id("X119");
  endfunction
endclass

`endif
