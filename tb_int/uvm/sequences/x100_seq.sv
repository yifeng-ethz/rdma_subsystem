`ifndef RDMA_SUBSYSTEM_SEQ_X100_SV
`define RDMA_SUBSYSTEM_SEQ_X100_SV

class seq_x100 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x100)

  function new(string name = "seq_x100");
    super.new(name);
    set_case_id("X100");
  endfunction
endclass

`endif
