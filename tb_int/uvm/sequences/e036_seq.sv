`ifndef RDMA_SUBSYSTEM_SEQ_E036_SV
`define RDMA_SUBSYSTEM_SEQ_E036_SV

class seq_e036 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e036)

  function new(string name = "seq_e036");
    super.new(name);
    set_case_id("E036");
  endfunction
endclass

`endif
