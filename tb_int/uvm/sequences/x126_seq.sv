`ifndef RDMA_SUBSYSTEM_SEQ_X126_SV
`define RDMA_SUBSYSTEM_SEQ_X126_SV

class seq_x126 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x126)

  function new(string name = "seq_x126");
    super.new(name);
    set_case_id("X126");
  endfunction
endclass

`endif
