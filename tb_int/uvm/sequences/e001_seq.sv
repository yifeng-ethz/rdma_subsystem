`ifndef RDMA_SUBSYSTEM_SEQ_E001_SV
`define RDMA_SUBSYSTEM_SEQ_E001_SV

class seq_e001 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e001)

  function new(string name = "seq_e001");
    super.new(name);
    set_case_id("E001");
  endfunction
endclass

`endif
