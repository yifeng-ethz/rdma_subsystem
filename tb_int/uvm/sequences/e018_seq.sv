`ifndef RDMA_SUBSYSTEM_SEQ_E018_SV
`define RDMA_SUBSYSTEM_SEQ_E018_SV

class seq_e018 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e018)

  function new(string name = "seq_e018");
    super.new(name);
    set_case_id("E018");
  endfunction
endclass

`endif
