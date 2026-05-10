`ifndef RDMA_SUBSYSTEM_SEQ_E084_SV
`define RDMA_SUBSYSTEM_SEQ_E084_SV

class seq_e084 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e084)

  function new(string name = "seq_e084");
    super.new(name);
    set_case_id("E084");
  endfunction
endclass

`endif
