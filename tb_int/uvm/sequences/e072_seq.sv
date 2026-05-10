`ifndef RDMA_SUBSYSTEM_SEQ_E072_SV
`define RDMA_SUBSYSTEM_SEQ_E072_SV

class seq_e072 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e072)

  function new(string name = "seq_e072");
    super.new(name);
    set_case_id("E072");
  endfunction
endclass

`endif
