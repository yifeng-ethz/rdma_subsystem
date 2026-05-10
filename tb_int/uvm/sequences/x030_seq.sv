`ifndef RDMA_SUBSYSTEM_SEQ_X030_SV
`define RDMA_SUBSYSTEM_SEQ_X030_SV

class seq_x030 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x030)

  function new(string name = "seq_x030");
    super.new(name);
    set_case_id("X030");
  endfunction
endclass

`endif
