`ifndef RDMA_SUBSYSTEM_SEQ_B015_SV
`define RDMA_SUBSYSTEM_SEQ_B015_SV

class seq_b015 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b015)

  function new(string name = "seq_b015");
    super.new(name);
    set_case_id("B015");
  endfunction
endclass

`endif
