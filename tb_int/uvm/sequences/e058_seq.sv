`ifndef RDMA_SUBSYSTEM_SEQ_E058_SV
`define RDMA_SUBSYSTEM_SEQ_E058_SV

class seq_e058 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e058)

  function new(string name = "seq_e058");
    super.new(name);
    set_case_id("E058");
  endfunction
endclass

`endif
