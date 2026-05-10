`ifndef RDMA_SUBSYSTEM_SEQ_E124_SV
`define RDMA_SUBSYSTEM_SEQ_E124_SV

class seq_e124 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e124)

  function new(string name = "seq_e124");
    super.new(name);
    set_case_id("E124");
  endfunction
endclass

`endif
