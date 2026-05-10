`ifndef RDMA_SUBSYSTEM_SEQ_E043_SV
`define RDMA_SUBSYSTEM_SEQ_E043_SV

class seq_e043 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e043)

  function new(string name = "seq_e043");
    super.new(name);
    set_case_id("E043");
  endfunction
endclass

`endif
