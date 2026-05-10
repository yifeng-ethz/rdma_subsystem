`ifndef RDMA_SUBSYSTEM_SEQ_P041_SV
`define RDMA_SUBSYSTEM_SEQ_P041_SV

class seq_p041 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p041)

  function new(string name = "seq_p041");
    super.new(name);
    set_case_id("P041");
  endfunction
endclass

`endif
