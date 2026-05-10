`ifndef RDMA_SUBSYSTEM_SEQ_P106_SV
`define RDMA_SUBSYSTEM_SEQ_P106_SV

class seq_p106 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p106)

  function new(string name = "seq_p106");
    super.new(name);
    set_case_id("P106");
  endfunction
endclass

`endif
