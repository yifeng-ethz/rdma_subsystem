`ifndef RDMA_SUBSYSTEM_SEQ_P075_SV
`define RDMA_SUBSYSTEM_SEQ_P075_SV

class seq_p075 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p075)

  function new(string name = "seq_p075");
    super.new(name);
    set_case_id("P075");
  endfunction
endclass

`endif
