`ifndef RDMA_SUBSYSTEM_SEQ_X054_SV
`define RDMA_SUBSYSTEM_SEQ_X054_SV

class seq_x054 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x054)

  function new(string name = "seq_x054");
    super.new(name);
    set_case_id("X054");
  endfunction
endclass

`endif
