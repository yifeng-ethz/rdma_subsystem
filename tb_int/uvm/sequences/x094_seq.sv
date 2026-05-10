`ifndef RDMA_SUBSYSTEM_SEQ_X094_SV
`define RDMA_SUBSYSTEM_SEQ_X094_SV

class seq_x094 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x094)

  function new(string name = "seq_x094");
    super.new(name);
    set_case_id("X094");
  endfunction
endclass

`endif
