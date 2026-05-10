`ifndef RDMA_SUBSYSTEM_SEQ_B118_SV
`define RDMA_SUBSYSTEM_SEQ_B118_SV

class seq_b118 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b118)

  function new(string name = "seq_b118");
    super.new(name);
    set_case_id("B118");
  endfunction
endclass

`endif
