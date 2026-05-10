`ifndef RDMA_SUBSYSTEM_SEQ_B061_SV
`define RDMA_SUBSYSTEM_SEQ_B061_SV

class seq_b061 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b061)

  function new(string name = "seq_b061");
    super.new(name);
    set_case_id("B061");
  endfunction
endclass

`endif
