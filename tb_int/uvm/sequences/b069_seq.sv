`ifndef RDMA_SUBSYSTEM_SEQ_B069_SV
`define RDMA_SUBSYSTEM_SEQ_B069_SV

class seq_b069 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b069)

  function new(string name = "seq_b069");
    super.new(name);
    set_case_id("B069");
  endfunction
endclass

`endif
