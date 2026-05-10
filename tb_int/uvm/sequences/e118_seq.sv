`ifndef RDMA_SUBSYSTEM_SEQ_E118_SV
`define RDMA_SUBSYSTEM_SEQ_E118_SV

class seq_e118 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e118)

  function new(string name = "seq_e118");
    super.new(name);
    set_case_id("E118");
  endfunction
endclass

`endif
