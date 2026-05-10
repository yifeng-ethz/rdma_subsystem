`ifndef RDMA_SUBSYSTEM_SEQ_P074_SV
`define RDMA_SUBSYSTEM_SEQ_P074_SV

class seq_p074 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p074)

  function new(string name = "seq_p074");
    super.new(name);
    set_case_id("P074");
  endfunction
endclass

`endif
