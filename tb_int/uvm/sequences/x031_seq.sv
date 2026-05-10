`ifndef RDMA_SUBSYSTEM_SEQ_X031_SV
`define RDMA_SUBSYSTEM_SEQ_X031_SV

class seq_x031 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x031)

  function new(string name = "seq_x031");
    super.new(name);
    set_case_id("X031");
  endfunction
endclass

`endif
