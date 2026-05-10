`ifndef RDMA_SUBSYSTEM_SEQ_X001_SV
`define RDMA_SUBSYSTEM_SEQ_X001_SV

class seq_x001 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x001)

  function new(string name = "seq_x001");
    super.new(name);
    set_case_id("X001");
  endfunction
endclass

`endif
