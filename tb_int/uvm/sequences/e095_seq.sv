`ifndef RDMA_SUBSYSTEM_SEQ_E095_SV
`define RDMA_SUBSYSTEM_SEQ_E095_SV

class seq_e095 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e095)

  function new(string name = "seq_e095");
    super.new(name);
    set_case_id("E095");
  endfunction
endclass

`endif
