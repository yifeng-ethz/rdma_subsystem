`ifndef RDMA_SUBSYSTEM_SEQ_P117_SV
`define RDMA_SUBSYSTEM_SEQ_P117_SV

class seq_p117 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p117)

  function new(string name = "seq_p117");
    super.new(name);
    set_case_id("P117");
  endfunction
endclass

`endif
