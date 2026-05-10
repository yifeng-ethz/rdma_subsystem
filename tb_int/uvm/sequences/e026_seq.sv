`ifndef RDMA_SUBSYSTEM_SEQ_E026_SV
`define RDMA_SUBSYSTEM_SEQ_E026_SV

class seq_e026 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e026)

  function new(string name = "seq_e026");
    super.new(name);
    set_case_id("E026");
  endfunction
endclass

`endif
