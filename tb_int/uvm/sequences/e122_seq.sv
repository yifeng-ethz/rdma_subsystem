`ifndef RDMA_SUBSYSTEM_SEQ_E122_SV
`define RDMA_SUBSYSTEM_SEQ_E122_SV

class seq_e122 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e122)

  function new(string name = "seq_e122");
    super.new(name);
    set_case_id("E122");
  endfunction
endclass

`endif
