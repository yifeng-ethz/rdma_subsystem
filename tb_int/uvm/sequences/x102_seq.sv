`ifndef RDMA_SUBSYSTEM_SEQ_X102_SV
`define RDMA_SUBSYSTEM_SEQ_X102_SV

class seq_x102 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x102)

  function new(string name = "seq_x102");
    super.new(name);
    set_case_id("X102");
  endfunction
endclass

`endif
