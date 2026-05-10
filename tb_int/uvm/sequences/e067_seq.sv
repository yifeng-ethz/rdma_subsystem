`ifndef RDMA_SUBSYSTEM_SEQ_E067_SV
`define RDMA_SUBSYSTEM_SEQ_E067_SV

class seq_e067 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e067)

  function new(string name = "seq_e067");
    super.new(name);
    set_case_id("E067");
  endfunction
endclass

`endif
