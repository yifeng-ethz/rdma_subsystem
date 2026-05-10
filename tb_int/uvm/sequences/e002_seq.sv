`ifndef RDMA_SUBSYSTEM_SEQ_E002_SV
`define RDMA_SUBSYSTEM_SEQ_E002_SV

class seq_e002 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e002)

  function new(string name = "seq_e002");
    super.new(name);
    set_case_id("E002");
  endfunction
endclass

`endif
