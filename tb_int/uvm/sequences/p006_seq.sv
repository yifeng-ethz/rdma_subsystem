`ifndef RDMA_SUBSYSTEM_SEQ_P006_SV
`define RDMA_SUBSYSTEM_SEQ_P006_SV

class seq_p006 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p006)

  function new(string name = "seq_p006");
    super.new(name);
    set_case_id("P006");
  endfunction
endclass

`endif
