`ifndef RDMA_SUBSYSTEM_SEQ_X117_SV
`define RDMA_SUBSYSTEM_SEQ_X117_SV

class seq_x117 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x117)

  function new(string name = "seq_x117");
    super.new(name);
    set_case_id("X117");
  endfunction
endclass

`endif
