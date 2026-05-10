`ifndef RDMA_SUBSYSTEM_SEQ_B102_SV
`define RDMA_SUBSYSTEM_SEQ_B102_SV

class seq_b102 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b102)

  function new(string name = "seq_b102");
    super.new(name);
    set_case_id("B102");
  endfunction
endclass

`endif
