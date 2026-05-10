`ifndef RDMA_SUBSYSTEM_SEQ_B099_SV
`define RDMA_SUBSYSTEM_SEQ_B099_SV

class seq_b099 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b099)

  function new(string name = "seq_b099");
    super.new(name);
    set_case_id("B099");
  endfunction
endclass

`endif
