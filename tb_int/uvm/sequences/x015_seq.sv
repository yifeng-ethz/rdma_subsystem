`ifndef RDMA_SUBSYSTEM_SEQ_X015_SV
`define RDMA_SUBSYSTEM_SEQ_X015_SV

class seq_x015 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x015)

  function new(string name = "seq_x015");
    super.new(name);
    set_case_id("X015");
  endfunction
endclass

`endif
