`ifndef RDMA_SUBSYSTEM_SEQ_B074_SV
`define RDMA_SUBSYSTEM_SEQ_B074_SV

class seq_b074 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b074)

  function new(string name = "seq_b074");
    super.new(name);
    set_case_id("B074");
  endfunction
endclass

`endif
