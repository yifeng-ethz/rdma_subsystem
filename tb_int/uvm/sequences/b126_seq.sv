`ifndef RDMA_SUBSYSTEM_SEQ_B126_SV
`define RDMA_SUBSYSTEM_SEQ_B126_SV

class seq_b126 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b126)

  function new(string name = "seq_b126");
    super.new(name);
    set_case_id("B126");
  endfunction
endclass

`endif
