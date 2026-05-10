`ifndef RDMA_SUBSYSTEM_SEQ_B042_SV
`define RDMA_SUBSYSTEM_SEQ_B042_SV

class seq_b042 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b042)

  function new(string name = "seq_b042");
    super.new(name);
    set_case_id("B042");
  endfunction
endclass

`endif
