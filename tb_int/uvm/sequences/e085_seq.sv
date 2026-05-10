`ifndef RDMA_SUBSYSTEM_SEQ_E085_SV
`define RDMA_SUBSYSTEM_SEQ_E085_SV

class seq_e085 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e085)

  function new(string name = "seq_e085");
    super.new(name);
    set_case_id("E085");
  endfunction
endclass

`endif
