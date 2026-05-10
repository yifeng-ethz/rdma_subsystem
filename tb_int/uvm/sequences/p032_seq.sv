`ifndef RDMA_SUBSYSTEM_SEQ_P032_SV
`define RDMA_SUBSYSTEM_SEQ_P032_SV

class seq_p032 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p032)

  function new(string name = "seq_p032");
    super.new(name);
    set_case_id("P032");
  endfunction
endclass

`endif
