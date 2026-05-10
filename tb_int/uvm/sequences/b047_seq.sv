`ifndef RDMA_SUBSYSTEM_SEQ_B047_SV
`define RDMA_SUBSYSTEM_SEQ_B047_SV

class seq_b047 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b047)

  function new(string name = "seq_b047");
    super.new(name);
    set_case_id("B047");
  endfunction
endclass

`endif
