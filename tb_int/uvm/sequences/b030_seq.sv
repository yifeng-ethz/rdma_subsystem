`ifndef RDMA_SUBSYSTEM_SEQ_B030_SV
`define RDMA_SUBSYSTEM_SEQ_B030_SV

class seq_b030 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b030)

  function new(string name = "seq_b030");
    super.new(name);
    set_case_id("B030");
  endfunction
endclass

`endif
