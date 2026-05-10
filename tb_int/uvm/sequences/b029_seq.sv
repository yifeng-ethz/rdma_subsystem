`ifndef RDMA_SUBSYSTEM_SEQ_B029_SV
`define RDMA_SUBSYSTEM_SEQ_B029_SV

class seq_b029 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b029)

  function new(string name = "seq_b029");
    super.new(name);
    set_case_id("B029");
  endfunction
endclass

`endif
