`ifndef RDMA_SUBSYSTEM_SEQ_E021_SV
`define RDMA_SUBSYSTEM_SEQ_E021_SV

class seq_e021 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e021)

  function new(string name = "seq_e021");
    super.new(name);
    set_case_id("E021");
  endfunction
endclass

`endif
