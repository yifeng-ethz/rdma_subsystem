`ifndef RDMA_SUBSYSTEM_SEQ_E056_SV
`define RDMA_SUBSYSTEM_SEQ_E056_SV

class seq_e056 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e056)

  function new(string name = "seq_e056");
    super.new(name);
    set_case_id("E056");
  endfunction
endclass

`endif
