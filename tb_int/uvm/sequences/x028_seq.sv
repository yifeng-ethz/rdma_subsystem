`ifndef RDMA_SUBSYSTEM_SEQ_X028_SV
`define RDMA_SUBSYSTEM_SEQ_X028_SV

class seq_x028 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x028)

  function new(string name = "seq_x028");
    super.new(name);
    set_case_id("X028");
  endfunction
endclass

`endif
