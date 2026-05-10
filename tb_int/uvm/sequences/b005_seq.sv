`ifndef RDMA_SUBSYSTEM_SEQ_B005_SV
`define RDMA_SUBSYSTEM_SEQ_B005_SV

class seq_b005 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b005)

  function new(string name = "seq_b005");
    super.new(name);
    set_case_id("B005");
  endfunction
endclass

`endif
