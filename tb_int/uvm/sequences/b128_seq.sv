`ifndef RDMA_SUBSYSTEM_SEQ_B128_SV
`define RDMA_SUBSYSTEM_SEQ_B128_SV

class seq_b128 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b128)

  function new(string name = "seq_b128");
    super.new(name);
    set_case_id("B128");
  endfunction
endclass

`endif
