`ifndef RDMA_SUBSYSTEM_SEQ_X065_SV
`define RDMA_SUBSYSTEM_SEQ_X065_SV

class seq_x065 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x065)

  function new(string name = "seq_x065");
    super.new(name);
    set_case_id("X065");
  endfunction
endclass

`endif
