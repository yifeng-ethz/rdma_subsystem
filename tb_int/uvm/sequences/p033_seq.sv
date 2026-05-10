`ifndef RDMA_SUBSYSTEM_SEQ_P033_SV
`define RDMA_SUBSYSTEM_SEQ_P033_SV

class seq_p033 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p033)

  function new(string name = "seq_p033");
    super.new(name);
    set_case_id("P033");
  endfunction
endclass

`endif
