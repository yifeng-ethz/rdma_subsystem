`ifndef RDMA_SUBSYSTEM_SEQ_X032_SV
`define RDMA_SUBSYSTEM_SEQ_X032_SV

class seq_x032 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x032)

  function new(string name = "seq_x032");
    super.new(name);
    set_case_id("X032");
  endfunction
endclass

`endif
