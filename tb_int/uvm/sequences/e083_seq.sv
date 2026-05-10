`ifndef RDMA_SUBSYSTEM_SEQ_E083_SV
`define RDMA_SUBSYSTEM_SEQ_E083_SV

class seq_e083 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e083)

  function new(string name = "seq_e083");
    super.new(name);
    set_case_id("E083");
  endfunction
endclass

`endif
