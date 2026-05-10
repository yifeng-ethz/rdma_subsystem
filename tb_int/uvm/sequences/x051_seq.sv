`ifndef RDMA_SUBSYSTEM_SEQ_X051_SV
`define RDMA_SUBSYSTEM_SEQ_X051_SV

class seq_x051 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x051)

  function new(string name = "seq_x051");
    super.new(name);
    set_case_id("X051");
  endfunction
endclass

`endif
