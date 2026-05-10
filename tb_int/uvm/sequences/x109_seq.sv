`ifndef RDMA_SUBSYSTEM_SEQ_X109_SV
`define RDMA_SUBSYSTEM_SEQ_X109_SV

class seq_x109 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x109)

  function new(string name = "seq_x109");
    super.new(name);
    set_case_id("X109");
  endfunction
endclass

`endif
