`ifndef RDMA_SUBSYSTEM_SEQ_X108_SV
`define RDMA_SUBSYSTEM_SEQ_X108_SV

class seq_x108 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x108)

  function new(string name = "seq_x108");
    super.new(name);
    set_case_id("X108");
  endfunction
endclass

`endif
