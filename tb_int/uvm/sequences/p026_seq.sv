`ifndef RDMA_SUBSYSTEM_SEQ_P026_SV
`define RDMA_SUBSYSTEM_SEQ_P026_SV

class seq_p026 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p026)

  function new(string name = "seq_p026");
    super.new(name);
    set_case_id("P026");
  endfunction
endclass

`endif
