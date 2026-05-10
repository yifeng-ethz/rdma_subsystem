`ifndef RDMA_SUBSYSTEM_SEQ_X125_SV
`define RDMA_SUBSYSTEM_SEQ_X125_SV

class seq_x125 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x125)

  function new(string name = "seq_x125");
    super.new(name);
    set_case_id("X125");
  endfunction
endclass

`endif
