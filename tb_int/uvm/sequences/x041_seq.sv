`ifndef RDMA_SUBSYSTEM_SEQ_X041_SV
`define RDMA_SUBSYSTEM_SEQ_X041_SV

class seq_x041 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x041)

  function new(string name = "seq_x041");
    super.new(name);
    set_case_id("X041");
  endfunction
endclass

`endif
