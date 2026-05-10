`ifndef RDMA_SUBSYSTEM_SEQ_X005_SV
`define RDMA_SUBSYSTEM_SEQ_X005_SV

class seq_x005 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x005)

  function new(string name = "seq_x005");
    super.new(name);
    set_case_id("X005");
  endfunction
endclass

`endif
