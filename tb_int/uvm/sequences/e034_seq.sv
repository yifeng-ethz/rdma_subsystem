`ifndef RDMA_SUBSYSTEM_SEQ_E034_SV
`define RDMA_SUBSYSTEM_SEQ_E034_SV

class seq_e034 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e034)

  function new(string name = "seq_e034");
    super.new(name);
    set_case_id("E034");
  endfunction
endclass

`endif
