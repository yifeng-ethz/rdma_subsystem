`ifndef RDMA_SUBSYSTEM_SEQ_X023_SV
`define RDMA_SUBSYSTEM_SEQ_X023_SV

class seq_x023 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x023)

  function new(string name = "seq_x023");
    super.new(name);
    set_case_id("X023");
  endfunction
endclass

`endif
