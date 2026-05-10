`ifndef RDMA_SUBSYSTEM_SEQ_X120_SV
`define RDMA_SUBSYSTEM_SEQ_X120_SV

class seq_x120 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x120)

  function new(string name = "seq_x120");
    super.new(name);
    set_case_id("X120");
  endfunction
endclass

`endif
