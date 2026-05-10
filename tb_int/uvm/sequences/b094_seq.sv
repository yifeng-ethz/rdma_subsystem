`ifndef RDMA_SUBSYSTEM_SEQ_B094_SV
`define RDMA_SUBSYSTEM_SEQ_B094_SV

class seq_b094 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b094)

  function new(string name = "seq_b094");
    super.new(name);
    set_case_id("B094");
  endfunction
endclass

`endif
