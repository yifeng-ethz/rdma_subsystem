`ifndef RDMA_SUBSYSTEM_SEQ_X101_SV
`define RDMA_SUBSYSTEM_SEQ_X101_SV

class seq_x101 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x101)

  function new(string name = "seq_x101");
    super.new(name);
    set_case_id("X101");
  endfunction
endclass

`endif
