`ifndef RDMA_SUBSYSTEM_SEQ_E060_SV
`define RDMA_SUBSYSTEM_SEQ_E060_SV

class seq_e060 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e060)

  function new(string name = "seq_e060");
    super.new(name);
    set_case_id("E060");
  endfunction
endclass

`endif
