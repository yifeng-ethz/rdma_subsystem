`ifndef RDMA_SUBSYSTEM_SEQ_P092_SV
`define RDMA_SUBSYSTEM_SEQ_P092_SV

class seq_p092 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p092)

  function new(string name = "seq_p092");
    super.new(name);
    set_case_id("P092");
  endfunction
endclass

`endif
