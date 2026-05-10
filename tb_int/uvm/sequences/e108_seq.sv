`ifndef RDMA_SUBSYSTEM_SEQ_E108_SV
`define RDMA_SUBSYSTEM_SEQ_E108_SV

class seq_e108 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e108)

  function new(string name = "seq_e108");
    super.new(name);
    set_case_id("E108");
  endfunction
endclass

`endif
