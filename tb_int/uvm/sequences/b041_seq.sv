`ifndef RDMA_SUBSYSTEM_SEQ_B041_SV
`define RDMA_SUBSYSTEM_SEQ_B041_SV

class seq_b041 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b041)

  function new(string name = "seq_b041");
    super.new(name);
    set_case_id("B041");
  endfunction
endclass

`endif
