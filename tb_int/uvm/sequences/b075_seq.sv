`ifndef RDMA_SUBSYSTEM_SEQ_B075_SV
`define RDMA_SUBSYSTEM_SEQ_B075_SV

class seq_b075 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b075)

  function new(string name = "seq_b075");
    super.new(name);
    set_case_id("B075");
  endfunction
endclass

`endif
