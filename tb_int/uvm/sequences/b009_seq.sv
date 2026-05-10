`ifndef RDMA_SUBSYSTEM_SEQ_B009_SV
`define RDMA_SUBSYSTEM_SEQ_B009_SV

class seq_b009 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b009)

  function new(string name = "seq_b009");
    super.new(name);
    set_case_id("B009");
  endfunction
endclass

`endif
