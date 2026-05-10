`ifndef RDMA_SUBSYSTEM_SEQ_B027_SV
`define RDMA_SUBSYSTEM_SEQ_B027_SV

class seq_b027 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b027)

  function new(string name = "seq_b027");
    super.new(name);
    set_case_id("B027");
  endfunction
endclass

`endif
