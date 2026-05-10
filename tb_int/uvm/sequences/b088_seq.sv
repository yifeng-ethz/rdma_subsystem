`ifndef RDMA_SUBSYSTEM_SEQ_B088_SV
`define RDMA_SUBSYSTEM_SEQ_B088_SV

class seq_b088 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b088)

  function new(string name = "seq_b088");
    super.new(name);
    set_case_id("B088");
  endfunction
endclass

`endif
