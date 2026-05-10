`ifndef RDMA_SUBSYSTEM_SEQ_E074_SV
`define RDMA_SUBSYSTEM_SEQ_E074_SV

class seq_e074 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e074)

  function new(string name = "seq_e074");
    super.new(name);
    set_case_id("E074");
  endfunction
endclass

`endif
