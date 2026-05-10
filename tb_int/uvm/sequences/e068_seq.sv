`ifndef RDMA_SUBSYSTEM_SEQ_E068_SV
`define RDMA_SUBSYSTEM_SEQ_E068_SV

class seq_e068 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e068)

  function new(string name = "seq_e068");
    super.new(name);
    set_case_id("E068");
  endfunction
endclass

`endif
