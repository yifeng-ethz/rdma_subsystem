`ifndef RDMA_SUBSYSTEM_SEQ_X088_SV
`define RDMA_SUBSYSTEM_SEQ_X088_SV

class seq_x088 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x088)

  function new(string name = "seq_x088");
    super.new(name);
    set_case_id("X088");
  endfunction
endclass

`endif
