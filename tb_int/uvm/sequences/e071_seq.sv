`ifndef RDMA_SUBSYSTEM_SEQ_E071_SV
`define RDMA_SUBSYSTEM_SEQ_E071_SV

class seq_e071 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e071)

  function new(string name = "seq_e071");
    super.new(name);
    set_case_id("E071");
  endfunction
endclass

`endif
