`ifndef RDMA_SUBSYSTEM_SEQ_E041_SV
`define RDMA_SUBSYSTEM_SEQ_E041_SV

class seq_e041 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e041)

  function new(string name = "seq_e041");
    super.new(name);
    set_case_id("E041");
  endfunction
endclass

`endif
