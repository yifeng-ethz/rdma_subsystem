`ifndef RDMA_SUBSYSTEM_SEQ_X107_SV
`define RDMA_SUBSYSTEM_SEQ_X107_SV

class seq_x107 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x107)

  function new(string name = "seq_x107");
    super.new(name);
    set_case_id("X107");
  endfunction
endclass

`endif
