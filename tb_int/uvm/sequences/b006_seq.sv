`ifndef RDMA_SUBSYSTEM_SEQ_B006_SV
`define RDMA_SUBSYSTEM_SEQ_B006_SV

class seq_b006 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b006)

  function new(string name = "seq_b006");
    super.new(name);
    set_case_id("B006");
  endfunction
endclass

`endif
