`ifndef RDMA_SUBSYSTEM_SEQ_E126_SV
`define RDMA_SUBSYSTEM_SEQ_E126_SV

class seq_e126 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e126)

  function new(string name = "seq_e126");
    super.new(name);
    set_case_id("E126");
  endfunction
endclass

`endif
