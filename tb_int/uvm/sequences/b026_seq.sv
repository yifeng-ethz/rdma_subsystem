`ifndef RDMA_SUBSYSTEM_SEQ_B026_SV
`define RDMA_SUBSYSTEM_SEQ_B026_SV

class seq_b026 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b026)

  function new(string name = "seq_b026");
    super.new(name);
    set_case_id("B026");
  endfunction
endclass

`endif
