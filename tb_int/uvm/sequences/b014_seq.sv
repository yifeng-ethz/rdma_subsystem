`ifndef RDMA_SUBSYSTEM_SEQ_B014_SV
`define RDMA_SUBSYSTEM_SEQ_B014_SV

class seq_b014 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b014)

  function new(string name = "seq_b014");
    super.new(name);
    set_case_id("B014");
  endfunction
endclass

`endif
