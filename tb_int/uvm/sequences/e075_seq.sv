`ifndef RDMA_SUBSYSTEM_SEQ_E075_SV
`define RDMA_SUBSYSTEM_SEQ_E075_SV

class seq_e075 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e075)

  function new(string name = "seq_e075");
    super.new(name);
    set_case_id("E075");
  endfunction
endclass

`endif
