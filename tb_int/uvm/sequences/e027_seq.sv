`ifndef RDMA_SUBSYSTEM_SEQ_E027_SV
`define RDMA_SUBSYSTEM_SEQ_E027_SV

class seq_e027 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e027)

  function new(string name = "seq_e027");
    super.new(name);
    set_case_id("E027");
  endfunction
endclass

`endif
