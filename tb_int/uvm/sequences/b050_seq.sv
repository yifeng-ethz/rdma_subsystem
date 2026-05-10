`ifndef RDMA_SUBSYSTEM_SEQ_B050_SV
`define RDMA_SUBSYSTEM_SEQ_B050_SV

class seq_b050 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b050)

  function new(string name = "seq_b050");
    super.new(name);
    set_case_id("B050");
  endfunction
endclass

`endif
