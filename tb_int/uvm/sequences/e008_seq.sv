`ifndef RDMA_SUBSYSTEM_SEQ_E008_SV
`define RDMA_SUBSYSTEM_SEQ_E008_SV

class seq_e008 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e008)

  function new(string name = "seq_e008");
    super.new(name);
    set_case_id("E008");
  endfunction
endclass

`endif
