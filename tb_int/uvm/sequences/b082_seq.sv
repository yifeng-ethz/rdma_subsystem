`ifndef RDMA_SUBSYSTEM_SEQ_B082_SV
`define RDMA_SUBSYSTEM_SEQ_B082_SV

class seq_b082 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b082)

  function new(string name = "seq_b082");
    super.new(name);
    set_case_id("B082");
  endfunction
endclass

`endif
