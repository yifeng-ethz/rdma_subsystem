`ifndef RDMA_SUBSYSTEM_SEQ_E046_SV
`define RDMA_SUBSYSTEM_SEQ_E046_SV

class seq_e046 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e046)

  function new(string name = "seq_e046");
    super.new(name);
    set_case_id("E046");
  endfunction
endclass

`endif
