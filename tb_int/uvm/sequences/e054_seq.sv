`ifndef RDMA_SUBSYSTEM_SEQ_E054_SV
`define RDMA_SUBSYSTEM_SEQ_E054_SV

class seq_e054 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e054)

  function new(string name = "seq_e054");
    super.new(name);
    set_case_id("E054");
  endfunction
endclass

`endif
