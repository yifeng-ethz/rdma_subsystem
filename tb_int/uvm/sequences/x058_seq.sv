`ifndef RDMA_SUBSYSTEM_SEQ_X058_SV
`define RDMA_SUBSYSTEM_SEQ_X058_SV

class seq_x058 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x058)

  function new(string name = "seq_x058");
    super.new(name);
    set_case_id("X058");
  endfunction
endclass

`endif
