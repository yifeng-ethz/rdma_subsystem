`ifndef RDMA_SUBSYSTEM_SEQ_X008_SV
`define RDMA_SUBSYSTEM_SEQ_X008_SV

class seq_x008 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x008)

  function new(string name = "seq_x008");
    super.new(name);
    set_case_id("X008");
  endfunction
endclass

`endif
