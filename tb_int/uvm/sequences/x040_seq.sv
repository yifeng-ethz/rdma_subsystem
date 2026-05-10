`ifndef RDMA_SUBSYSTEM_SEQ_X040_SV
`define RDMA_SUBSYSTEM_SEQ_X040_SV

class seq_x040 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x040)

  function new(string name = "seq_x040");
    super.new(name);
    set_case_id("X040");
  endfunction
endclass

`endif
