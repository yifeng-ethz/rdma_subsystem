`ifndef RDMA_SUBSYSTEM_SEQ_X097_SV
`define RDMA_SUBSYSTEM_SEQ_X097_SV

class seq_x097 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x097)

  function new(string name = "seq_x097");
    super.new(name);
    set_case_id("X097");
  endfunction
endclass

`endif
