`ifndef RDMA_SUBSYSTEM_SEQ_X056_SV
`define RDMA_SUBSYSTEM_SEQ_X056_SV

class seq_x056 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x056)

  function new(string name = "seq_x056");
    super.new(name);
    set_case_id("X056");
  endfunction
endclass

`endif
