`ifndef RDMA_SUBSYSTEM_SEQ_E081_SV
`define RDMA_SUBSYSTEM_SEQ_E081_SV

class seq_e081 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e081)

  function new(string name = "seq_e081");
    super.new(name);
    set_case_id("E081");
  endfunction
endclass

`endif
