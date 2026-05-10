`ifndef RDMA_SUBSYSTEM_SEQ_E073_SV
`define RDMA_SUBSYSTEM_SEQ_E073_SV

class seq_e073 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e073)

  function new(string name = "seq_e073");
    super.new(name);
    set_case_id("E073");
  endfunction
endclass

`endif
