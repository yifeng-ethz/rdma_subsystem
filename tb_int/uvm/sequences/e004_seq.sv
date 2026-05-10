`ifndef RDMA_SUBSYSTEM_SEQ_E004_SV
`define RDMA_SUBSYSTEM_SEQ_E004_SV

class seq_e004 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e004)

  function new(string name = "seq_e004");
    super.new(name);
    set_case_id("E004");
  endfunction
endclass

`endif
