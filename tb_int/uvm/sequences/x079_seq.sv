`ifndef RDMA_SUBSYSTEM_SEQ_X079_SV
`define RDMA_SUBSYSTEM_SEQ_X079_SV

class seq_x079 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x079)

  function new(string name = "seq_x079");
    super.new(name);
    set_case_id("X079");
  endfunction
endclass

`endif
