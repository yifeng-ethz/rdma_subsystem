`ifndef RDMA_SUBSYSTEM_SEQ_P104_SV
`define RDMA_SUBSYSTEM_SEQ_P104_SV

class seq_p104 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p104)

  function new(string name = "seq_p104");
    super.new(name);
    set_case_id("P104");
  endfunction
endclass

`endif
