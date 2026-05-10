`ifndef RDMA_SUBSYSTEM_SEQ_X022_SV
`define RDMA_SUBSYSTEM_SEQ_X022_SV

class seq_x022 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x022)

  function new(string name = "seq_x022");
    super.new(name);
    set_case_id("X022");
  endfunction
endclass

`endif
