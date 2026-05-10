`ifndef RDMA_SUBSYSTEM_SEQ_P004_SV
`define RDMA_SUBSYSTEM_SEQ_P004_SV

class seq_p004 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p004)

  function new(string name = "seq_p004");
    super.new(name);
    set_case_id("P004");
  endfunction
endclass

`endif
