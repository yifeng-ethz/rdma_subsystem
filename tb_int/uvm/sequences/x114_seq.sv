`ifndef RDMA_SUBSYSTEM_SEQ_X114_SV
`define RDMA_SUBSYSTEM_SEQ_X114_SV

class seq_x114 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x114)

  function new(string name = "seq_x114");
    super.new(name);
    set_case_id("X114");
  endfunction
endclass

`endif
