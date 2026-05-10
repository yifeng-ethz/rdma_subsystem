`ifndef RDMA_SUBSYSTEM_SEQ_E025_SV
`define RDMA_SUBSYSTEM_SEQ_E025_SV

class seq_e025 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e025)

  function new(string name = "seq_e025");
    super.new(name);
    set_case_id("E025");
  endfunction
endclass

`endif
