`ifndef RDMA_SUBSYSTEM_SEQ_E128_SV
`define RDMA_SUBSYSTEM_SEQ_E128_SV

class seq_e128 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e128)

  function new(string name = "seq_e128");
    super.new(name);
    set_case_id("E128");
  endfunction
endclass

`endif
