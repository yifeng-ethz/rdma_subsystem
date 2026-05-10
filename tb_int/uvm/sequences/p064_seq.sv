`ifndef RDMA_SUBSYSTEM_SEQ_P064_SV
`define RDMA_SUBSYSTEM_SEQ_P064_SV

class seq_p064 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p064)

  function new(string name = "seq_p064");
    super.new(name);
    set_case_id("P064");
  endfunction
endclass

`endif
