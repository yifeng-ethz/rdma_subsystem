`ifndef RDMA_SUBSYSTEM_SEQ_E048_SV
`define RDMA_SUBSYSTEM_SEQ_E048_SV

class seq_e048 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e048)

  function new(string name = "seq_e048");
    super.new(name);
    set_case_id("E048");
  endfunction
endclass

`endif
