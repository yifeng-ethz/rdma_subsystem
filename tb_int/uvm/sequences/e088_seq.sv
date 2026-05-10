`ifndef RDMA_SUBSYSTEM_SEQ_E088_SV
`define RDMA_SUBSYSTEM_SEQ_E088_SV

class seq_e088 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e088)

  function new(string name = "seq_e088");
    super.new(name);
    set_case_id("E088");
  endfunction
endclass

`endif
