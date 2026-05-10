`ifndef RDMA_SUBSYSTEM_SEQ_X016_SV
`define RDMA_SUBSYSTEM_SEQ_X016_SV

class seq_x016 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x016)

  function new(string name = "seq_x016");
    super.new(name);
    set_case_id("X016");
  endfunction
endclass

`endif
