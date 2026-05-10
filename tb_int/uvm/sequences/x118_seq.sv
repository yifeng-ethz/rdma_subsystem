`ifndef RDMA_SUBSYSTEM_SEQ_X118_SV
`define RDMA_SUBSYSTEM_SEQ_X118_SV

class seq_x118 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x118)

  function new(string name = "seq_x118");
    super.new(name);
    set_case_id("X118");
  endfunction
endclass

`endif
