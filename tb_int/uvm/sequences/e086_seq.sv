`ifndef RDMA_SUBSYSTEM_SEQ_E086_SV
`define RDMA_SUBSYSTEM_SEQ_E086_SV

class seq_e086 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e086)

  function new(string name = "seq_e086");
    super.new(name);
    set_case_id("E086");
  endfunction
endclass

`endif
