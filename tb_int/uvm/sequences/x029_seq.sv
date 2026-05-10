`ifndef RDMA_SUBSYSTEM_SEQ_X029_SV
`define RDMA_SUBSYSTEM_SEQ_X029_SV

class seq_x029 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x029)

  function new(string name = "seq_x029");
    super.new(name);
    set_case_id("X029");
  endfunction
endclass

`endif
