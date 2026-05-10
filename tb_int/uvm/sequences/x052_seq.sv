`ifndef RDMA_SUBSYSTEM_SEQ_X052_SV
`define RDMA_SUBSYSTEM_SEQ_X052_SV

class seq_x052 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x052)

  function new(string name = "seq_x052");
    super.new(name);
    set_case_id("X052");
  endfunction
endclass

`endif
