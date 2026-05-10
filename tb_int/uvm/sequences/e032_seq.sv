`ifndef RDMA_SUBSYSTEM_SEQ_E032_SV
`define RDMA_SUBSYSTEM_SEQ_E032_SV

class seq_e032 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e032)

  function new(string name = "seq_e032");
    super.new(name);
    set_case_id("E032");
  endfunction
endclass

`endif
