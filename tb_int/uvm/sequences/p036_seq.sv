`ifndef RDMA_SUBSYSTEM_SEQ_P036_SV
`define RDMA_SUBSYSTEM_SEQ_P036_SV

class seq_p036 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p036)

  function new(string name = "seq_p036");
    super.new(name);
    set_case_id("P036");
  endfunction
endclass

`endif
