`ifndef RDMA_SUBSYSTEM_SEQ_B096_SV
`define RDMA_SUBSYSTEM_SEQ_B096_SV

class seq_b096 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b096)

  function new(string name = "seq_b096");
    super.new(name);
    set_case_id("B096");
  endfunction
endclass

`endif
