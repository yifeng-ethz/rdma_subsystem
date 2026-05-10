`ifndef RDMA_SUBSYSTEM_SEQ_X007_SV
`define RDMA_SUBSYSTEM_SEQ_X007_SV

class seq_x007 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x007)

  function new(string name = "seq_x007");
    super.new(name);
    set_case_id("X007");
  endfunction
endclass

`endif
