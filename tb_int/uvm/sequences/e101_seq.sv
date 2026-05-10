`ifndef RDMA_SUBSYSTEM_SEQ_E101_SV
`define RDMA_SUBSYSTEM_SEQ_E101_SV

class seq_e101 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e101)

  function new(string name = "seq_e101");
    super.new(name);
    set_case_id("E101");
  endfunction
endclass

`endif
