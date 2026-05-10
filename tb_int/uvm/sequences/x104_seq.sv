`ifndef RDMA_SUBSYSTEM_SEQ_X104_SV
`define RDMA_SUBSYSTEM_SEQ_X104_SV

class seq_x104 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x104)

  function new(string name = "seq_x104");
    super.new(name);
    set_case_id("X104");
  endfunction
endclass

`endif
