`ifndef RDMA_SUBSYSTEM_SEQ_P051_SV
`define RDMA_SUBSYSTEM_SEQ_P051_SV

class seq_p051 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p051)

  function new(string name = "seq_p051");
    super.new(name);
    set_case_id("P051");
  endfunction
endclass

`endif
