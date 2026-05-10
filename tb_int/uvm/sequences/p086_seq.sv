`ifndef RDMA_SUBSYSTEM_SEQ_P086_SV
`define RDMA_SUBSYSTEM_SEQ_P086_SV

class seq_p086 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p086)

  function new(string name = "seq_p086");
    super.new(name);
    set_case_id("P086");
  endfunction
endclass

`endif
