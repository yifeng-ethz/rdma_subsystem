`ifndef RDMA_SUBSYSTEM_SEQ_X024_SV
`define RDMA_SUBSYSTEM_SEQ_X024_SV

class seq_x024 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x024)

  function new(string name = "seq_x024");
    super.new(name);
    set_case_id("X024");
  endfunction
endclass

`endif
