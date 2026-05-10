`ifndef RDMA_SUBSYSTEM_SEQ_E096_SV
`define RDMA_SUBSYSTEM_SEQ_E096_SV

class seq_e096 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e096)

  function new(string name = "seq_e096");
    super.new(name);
    set_case_id("E096");
  endfunction
endclass

`endif
