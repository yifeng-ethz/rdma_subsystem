`ifndef RDMA_SUBSYSTEM_SEQ_P048_SV
`define RDMA_SUBSYSTEM_SEQ_P048_SV

class seq_p048 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p048)

  function new(string name = "seq_p048");
    super.new(name);
    set_case_id("P048");
  endfunction
endclass

`endif
