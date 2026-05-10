`ifndef RDMA_SUBSYSTEM_SEQ_E106_SV
`define RDMA_SUBSYSTEM_SEQ_E106_SV

class seq_e106 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e106)

  function new(string name = "seq_e106");
    super.new(name);
    set_case_id("E106");
  endfunction
endclass

`endif
