`ifndef RDMA_SUBSYSTEM_SEQ_E006_SV
`define RDMA_SUBSYSTEM_SEQ_E006_SV

class seq_e006 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e006)

  function new(string name = "seq_e006");
    super.new(name);
    set_case_id("E006");
  endfunction
endclass

`endif
