`ifndef RDMA_SUBSYSTEM_SEQ_X074_SV
`define RDMA_SUBSYSTEM_SEQ_X074_SV

class seq_x074 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x074)

  function new(string name = "seq_x074");
    super.new(name);
    set_case_id("X074");
  endfunction
endclass

`endif
