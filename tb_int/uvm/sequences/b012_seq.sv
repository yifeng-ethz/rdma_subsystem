`ifndef RDMA_SUBSYSTEM_SEQ_B012_SV
`define RDMA_SUBSYSTEM_SEQ_B012_SV

class seq_b012 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b012)

  function new(string name = "seq_b012");
    super.new(name);
    set_case_id("B012");
  endfunction
endclass

`endif
