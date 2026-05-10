`ifndef RDMA_SUBSYSTEM_SEQ_E111_SV
`define RDMA_SUBSYSTEM_SEQ_E111_SV

class seq_e111 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e111)

  function new(string name = "seq_e111");
    super.new(name);
    set_case_id("E111");
  endfunction
endclass

`endif
