`ifndef RDMA_SUBSYSTEM_SEQ_E120_SV
`define RDMA_SUBSYSTEM_SEQ_E120_SV

class seq_e120 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e120)

  function new(string name = "seq_e120");
    super.new(name);
    set_case_id("E120");
  endfunction
endclass

`endif
