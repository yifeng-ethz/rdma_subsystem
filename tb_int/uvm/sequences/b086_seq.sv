`ifndef RDMA_SUBSYSTEM_SEQ_B086_SV
`define RDMA_SUBSYSTEM_SEQ_B086_SV

class seq_b086 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b086)

  function new(string name = "seq_b086");
    super.new(name);
    set_case_id("B086");
  endfunction
endclass

`endif
