`ifndef RDMA_SUBSYSTEM_SEQ_B011_SV
`define RDMA_SUBSYSTEM_SEQ_B011_SV

class seq_b011 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b011)

  function new(string name = "seq_b011");
    super.new(name);
    set_case_id("B011");
  endfunction
endclass

`endif
