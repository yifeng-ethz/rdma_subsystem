`ifndef RDMA_SUBSYSTEM_SEQ_E078_SV
`define RDMA_SUBSYSTEM_SEQ_E078_SV

class seq_e078 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e078)

  function new(string name = "seq_e078");
    super.new(name);
    set_case_id("E078");
  endfunction
endclass

`endif
