`ifndef RDMA_SUBSYSTEM_SEQ_P005_SV
`define RDMA_SUBSYSTEM_SEQ_P005_SV

class seq_p005 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p005)

  function new(string name = "seq_p005");
    super.new(name);
    set_case_id("P005");
  endfunction
endclass

`endif
