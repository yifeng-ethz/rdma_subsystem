`ifndef RDMA_SUBSYSTEM_SEQ_B073_SV
`define RDMA_SUBSYSTEM_SEQ_B073_SV

class seq_b073 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b073)

  function new(string name = "seq_b073");
    super.new(name);
    set_case_id("B073");
  endfunction
endclass

`endif
