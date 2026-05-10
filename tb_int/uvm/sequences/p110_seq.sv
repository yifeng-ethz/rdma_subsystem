`ifndef RDMA_SUBSYSTEM_SEQ_P110_SV
`define RDMA_SUBSYSTEM_SEQ_P110_SV

class seq_p110 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p110)

  function new(string name = "seq_p110");
    super.new(name);
    set_case_id("P110");
  endfunction
endclass

`endif
