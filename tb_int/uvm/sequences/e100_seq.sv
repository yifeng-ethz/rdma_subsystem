`ifndef RDMA_SUBSYSTEM_SEQ_E100_SV
`define RDMA_SUBSYSTEM_SEQ_E100_SV

class seq_e100 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e100)

  function new(string name = "seq_e100");
    super.new(name);
    set_case_id("E100");
  endfunction
endclass

`endif
