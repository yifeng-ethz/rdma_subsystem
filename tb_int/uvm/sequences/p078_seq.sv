`ifndef RDMA_SUBSYSTEM_SEQ_P078_SV
`define RDMA_SUBSYSTEM_SEQ_P078_SV

class seq_p078 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p078)

  function new(string name = "seq_p078");
    super.new(name);
    set_case_id("P078");
  endfunction
endclass

`endif
