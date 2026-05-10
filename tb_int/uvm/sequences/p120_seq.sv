`ifndef RDMA_SUBSYSTEM_SEQ_P120_SV
`define RDMA_SUBSYSTEM_SEQ_P120_SV

class seq_p120 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p120)

  function new(string name = "seq_p120");
    super.new(name);
    set_case_id("P120");
  endfunction
endclass

`endif
