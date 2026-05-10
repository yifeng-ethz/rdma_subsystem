`ifndef RDMA_SUBSYSTEM_SEQ_P008_SV
`define RDMA_SUBSYSTEM_SEQ_P008_SV

class seq_p008 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p008)

  function new(string name = "seq_p008");
    super.new(name);
    set_case_id("P008");
  endfunction
endclass

`endif
