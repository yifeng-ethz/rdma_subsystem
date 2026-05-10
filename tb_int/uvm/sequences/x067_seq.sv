`ifndef RDMA_SUBSYSTEM_SEQ_X067_SV
`define RDMA_SUBSYSTEM_SEQ_X067_SV

class seq_x067 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x067)

  function new(string name = "seq_x067");
    super.new(name);
    set_case_id("X067");
  endfunction
endclass

`endif
