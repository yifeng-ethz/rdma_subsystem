`ifndef RDMA_SUBSYSTEM_SEQ_X060_SV
`define RDMA_SUBSYSTEM_SEQ_X060_SV

class seq_x060 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x060)

  function new(string name = "seq_x060");
    super.new(name);
    set_case_id("X060");
  endfunction
endclass

`endif
