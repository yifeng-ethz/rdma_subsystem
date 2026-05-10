`ifndef RDMA_SUBSYSTEM_SEQ_B001_SV
`define RDMA_SUBSYSTEM_SEQ_B001_SV

class seq_b001 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b001)

  function new(string name = "seq_b001");
    super.new(name);
    set_case_id("B001");
  endfunction
endclass

`endif
