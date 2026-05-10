`ifndef RDMA_SUBSYSTEM_SEQ_B125_SV
`define RDMA_SUBSYSTEM_SEQ_B125_SV

class seq_b125 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b125)

  function new(string name = "seq_b125");
    super.new(name);
    set_case_id("B125");
  endfunction
endclass

`endif
