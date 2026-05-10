`ifndef RDMA_SUBSYSTEM_SEQ_P012_SV
`define RDMA_SUBSYSTEM_SEQ_P012_SV

class seq_p012 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p012)

  function new(string name = "seq_p012");
    super.new(name);
    set_case_id("P012");
  endfunction
endclass

`endif
