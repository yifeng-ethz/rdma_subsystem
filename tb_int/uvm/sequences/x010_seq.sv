`ifndef RDMA_SUBSYSTEM_SEQ_X010_SV
`define RDMA_SUBSYSTEM_SEQ_X010_SV

class seq_x010 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x010)

  function new(string name = "seq_x010");
    super.new(name);
    set_case_id("X010");
  endfunction
endclass

`endif
