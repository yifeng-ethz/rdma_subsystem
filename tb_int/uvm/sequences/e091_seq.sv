`ifndef RDMA_SUBSYSTEM_SEQ_E091_SV
`define RDMA_SUBSYSTEM_SEQ_E091_SV

class seq_e091 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e091)

  function new(string name = "seq_e091");
    super.new(name);
    set_case_id("E091");
  endfunction
endclass

`endif
