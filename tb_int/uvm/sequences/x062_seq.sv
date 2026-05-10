`ifndef RDMA_SUBSYSTEM_SEQ_X062_SV
`define RDMA_SUBSYSTEM_SEQ_X062_SV

class seq_x062 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x062)

  function new(string name = "seq_x062");
    super.new(name);
    set_case_id("X062");
  endfunction
endclass

`endif
