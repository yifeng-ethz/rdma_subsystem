# rdma_subsystem tb_int

Integration UVM cosim for the four-IP RDMA subsystem.  The FEB is abstracted at
the OPQ egress boundary; the source agent emits byte-level mu3e frames with OPQ
K-character markers.  The run_tool behavior is modeled in SystemVerilog and
owns host CSR/RQ/CQ sequencing.

Primary commands:

```bash
make -C tb_int/uvm generate
make -C tb_int/uvm TEST=test_b001_catalog CASE_ID=B001 run_one
make -C tb_int/uvm regress
python3 ~/.codex/skills/dv-workflow/scripts/dv_report_gen.py tb_int
```

`tb_int/uvm/rdma_subsystem_stub.sv` is a bootstrap fallback used only when the
sibling-owned real `rtl/rdma_subsystem_top.sv` is absent.
