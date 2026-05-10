`ifndef RDMA_SUBSYSTEM_SEQ_E125_SV
`define RDMA_SUBSYSTEM_SEQ_E125_SV

class seq_e125 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e125)

  function new(string name = "seq_e125");
    super.new(name);
    set_case_id("E125");
  endfunction
endclass

`endif
