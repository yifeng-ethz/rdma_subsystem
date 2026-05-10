`ifndef RDMA_SUBSYSTEM_SEQ_B058_SV
`define RDMA_SUBSYSTEM_SEQ_B058_SV

class seq_b058 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b058)

  function new(string name = "seq_b058");
    super.new(name);
    set_case_id("B058");
  endfunction
endclass

`endif
