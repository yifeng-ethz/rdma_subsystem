`ifndef RDMA_SUBSYSTEM_SEQ_P123_SV
`define RDMA_SUBSYSTEM_SEQ_P123_SV

class seq_p123 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p123)

  function new(string name = "seq_p123");
    super.new(name);
    set_case_id("P123");
  endfunction
endclass

`endif
