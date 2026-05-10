`ifndef RDMA_SUBSYSTEM_SEQ_X014_SV
`define RDMA_SUBSYSTEM_SEQ_X014_SV

class seq_x014 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x014)

  function new(string name = "seq_x014");
    super.new(name);
    set_case_id("X014");
  endfunction
endclass

`endif
