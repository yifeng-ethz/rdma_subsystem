`ifndef RDMA_SUBSYSTEM_SEQ_X071_SV
`define RDMA_SUBSYSTEM_SEQ_X071_SV

class seq_x071 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x071)

  function new(string name = "seq_x071");
    super.new(name);
    set_case_id("X071");
  endfunction
endclass

`endif
