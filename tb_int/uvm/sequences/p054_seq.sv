`ifndef RDMA_SUBSYSTEM_SEQ_P054_SV
`define RDMA_SUBSYSTEM_SEQ_P054_SV

class seq_p054 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p054)

  function new(string name = "seq_p054");
    super.new(name);
    set_case_id("P054");
  endfunction
endclass

`endif
