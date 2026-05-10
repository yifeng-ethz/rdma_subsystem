`ifndef RDMA_SUBSYSTEM_SEQ_P114_SV
`define RDMA_SUBSYSTEM_SEQ_P114_SV

class seq_p114 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p114)

  function new(string name = "seq_p114");
    super.new(name);
    set_case_id("P114");
  endfunction
endclass

`endif
