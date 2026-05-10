TB_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
UVM_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
IP_DIR := $(abspath $(TB_DIR)/..)

QUESTA_HOME ?= /data1/questaone_sim/questasim
ETH_LIC_SERVER := 8161@lic-mentor.ethz.ch
export LM_LICENSE_FILE := $(ETH_LIC_SERVER)
export MGLS_LICENSE_FILE := $(LM_LICENSE_FILE)
export SALT_LICENSE_SERVER := $(LM_LICENSE_FILE)
export QSIM_INI := $(QUESTA_HOME)/modelsim.ini

VLIB := $(QUESTA_HOME)/linux_x86_64/vlib
VMAP := $(QUESTA_HOME)/linux_x86_64/vmap
VLOG := $(QUESTA_HOME)/linux_x86_64/vlog
VSIM := $(QUESTA_HOME)/linux_x86_64/vsim
VCOVER := $(QUESTA_HOME)/linux_x86_64/vcover
PYTHON ?= python3

-include $(UVM_DIR)/case_catalog.mk

UVM_PKG := $(firstword $(wildcard \
  $(QUESTA_HOME)/verilog_src/questa_uvm_pkg-1.2/src/uvm_pkg.sv \
  $(QUESTA_HOME)/verilog_src/uvm-1.2/src/uvm_pkg.sv))
UVM_SRC := $(dir $(UVM_PKG))
UVM_DPI_SO := $(firstword $(wildcard \
  $(QUESTA_HOME)/uvm-1.2/linux_x86_64/uvm_dpi.so \
  $(QUESTA_HOME)/verilog_src/uvm-1.2/linux_x86_64/uvm_dpi.so))
UVM_DPI_LIB := $(basename $(UVM_DPI_SO))

DEBUG_LEVEL ?= 1
BUILD_DIR ?= $(UVM_DIR)/build/dbg$(DEBUG_LEVEL)
WORK_DIR := $(BUILD_DIR)/work
MODELSIM_INI := $(BUILD_DIR)/modelsim.ini
TOP := tb_top
TEST ?= rdma_subsystem_phase_b_test
CASE_ID ?= B001
SEED ?= 1
COV_CODE ?= sbecft
EXTRA_PLUSARGS ?=

ifeq ($(DEBUG_LEVEL),1)
COV_DIR := $(UVM_DIR)/cov_after/dbg1
else
COV_DIR := $(UVM_DIR)/cov_after/dbg$(DEBUG_LEVEL)
endif
LOG_DIR := $(UVM_DIR)/logs/dbg$(DEBUG_LEVEL)
FLAT_LOG := $(UVM_DIR)/logs/$(CASE_ID)_dbg$(DEBUG_LEVEL)_s$(SEED).log
UCDB := $(COV_DIR)/$(CASE_ID)_s$(SEED).ucdb
SCORECARD := $(COV_DIR)/$(CASE_ID).scorecard.json

RTL_PKG := $(IP_DIR)/rtl/rdma_subsystem_pkg.sv
RTL_SRCS_RAW := $(sort $(wildcard $(IP_DIR)/rtl/*.sv))
RTL_SRCS := $(if $(wildcard $(RTL_PKG)),$(RTL_PKG) $(filter-out $(RTL_PKG),$(RTL_SRCS_RAW)),$(RTL_SRCS_RAW))
SIBLING_RTL_SRCS := \
  $(sort $(wildcard $(IP_DIR)/../rdma_dma_engine/rtl/*.sv)) \
  $(sort $(wildcard $(IP_DIR)/../rdma_sq_fetcher/rtl/*.sv)) \
  $(sort $(wildcard $(IP_DIR)/../rdma_cq_pusher/rtl/*.sv)) \
  $(sort $(wildcard $(IP_DIR)/../rdma_run_manager/rtl/*.sv))
ifeq ($(strip $(RTL_SRCS)),)
DUT_SRCS := $(UVM_DIR)/rdma_subsystem_stub.sv
else
DUT_SRCS := $(SIBLING_RTL_SRCS) $(RTL_SRCS)
endif

SV_SRCS := \
  $(UVM_PKG) \
  $(UVM_DIR)/subsystem_if.sv \
  $(UVM_DIR)/subsystem_case_pkg.sv \
  $(DUT_SRCS) \
  $(UVM_DIR)/agents/opq_source_agent/opq_source_pkg.sv \
  $(UVM_DIR)/agents/host_axi_completer_agent/host_axi_completer_pkg.sv \
  $(UVM_DIR)/agents/runtool_model_agent/runtool_model_pkg.sv \
  $(UVM_DIR)/subsystem_env_pkg.sv \
  $(UVM_DIR)/tb_top.sv

VLOG_FLAGS := -ini $(MODELSIM_INI) -sv -work work \
  +incdir+$(UVM_SRC) \
  +incdir+$(UVM_DIR) \
  +incdir+$(UVM_DIR)/agents/opq_source_agent \
  +incdir+$(UVM_DIR)/agents/host_axi_completer_agent \
  +incdir+$(UVM_DIR)/agents/runtool_model_agent \
  +incdir+$(UVM_DIR)/tests \
  +define+DEBUG_LEVEL=$(DEBUG_LEVEL) +cover=$(COV_CODE)

VSIM_FLAGS := -ini $(MODELSIM_INI) -c -suppress 19 -suppress 3009 -coverage -work work
ifneq ($(strip $(UVM_DPI_LIB)),)
VSIM_FLAGS += -sv_lib $(UVM_DPI_LIB)
endif

.PHONY: all generate prepare compile compile_dbg1 compile_dbg2 run_one run_one_nocompile smoke regress_dbg1 regress_dbg2 regress cross_validate merge_coverage report format_check ascii_check unique_coverage clean

all: smoke

generate:
	$(PYTHON) $(UVM_DIR)/scripts/gen_tb_int_phase_b.py

prepare:
	mkdir -p $(BUILD_DIR) $(COV_DIR) $(LOG_DIR) $(UVM_DIR)/logs $(UVM_DIR)/cov_after
	@if [ ! -f "$(MODELSIM_INI)" ]; then cp "$(QUESTA_HOME)/modelsim.ini" "$(MODELSIM_INI)"; chmod u+w "$(MODELSIM_INI)"; fi
	@if [ ! -f "$(WORK_DIR)/_info" ]; then cd "$(BUILD_DIR)" && "$(VLIB)" work; fi
	cd "$(BUILD_DIR)" && "$(VMAP)" -modelsimini "$(MODELSIM_INI)" work "$(WORK_DIR)" >/dev/null

compile: generate prepare
	$(VLOG) $(VLOG_FLAGS) $(SV_SRCS)

compile_dbg1:
	$(MAKE) DEBUG_LEVEL=1 compile

compile_dbg2:
	$(MAKE) DEBUG_LEVEL=2 compile

run_one: compile
	$(MAKE) DEBUG_LEVEL=$(DEBUG_LEVEL) TEST=$(TEST) CASE_ID=$(CASE_ID) SEED=$(SEED) run_one_nocompile

run_one_nocompile: prepare
	$(VSIM) $(VSIM_FLAGS) $(TOP) \
	  +UVM_TESTNAME=$(TEST) +CASE_ID=$(CASE_ID) +DEBUG_LEVEL=$(DEBUG_LEVEL) \
	  $(EXTRA_PLUSARGS) \
	  +SCORECARD=$(SCORECARD) -sv_seed $(SEED) -l $(FLAT_LOG) \
	  -do "coverage save -onexit $(UCDB); run -all; quit -f"
	$(PYTHON) $(UVM_DIR)/scripts/check_uvm_log.py $(FLAT_LOG)
	@if [ "$(DEBUG_LEVEL)" = "1" ]; then cp "$(UCDB)" "$(UVM_DIR)/cov_after/$(CASE_ID).ucdb"; cp "$(UCDB)" "$(UVM_DIR)/cov_after/$(CASE_ID)_s$(SEED).ucdb"; cp "$(SCORECARD)" "$(UVM_DIR)/cov_after/$(CASE_ID).scorecard.json"; fi

smoke:
	$(MAKE) DEBUG_LEVEL=1 TEST=test_b001_catalog CASE_ID=B001 run_one
	$(MAKE) DEBUG_LEVEL=2 TEST=test_b001_catalog CASE_ID=B001 run_one

regress_dbg1: compile_dbg1
	@for entry in $(RDMA_SUBSYS_ALL_CASES); do \
	  test_name=$${entry%%:*}; case_id=$${entry##*:}; \
	  $(MAKE) DEBUG_LEVEL=1 TEST=$$test_name CASE_ID=$$case_id run_one_nocompile || exit $$?; \
	done

regress_dbg2: compile_dbg2
	@for entry in $(RDMA_SUBSYS_ALL_CASES); do \
	  test_name=$${entry%%:*}; case_id=$${entry##*:}; \
	  $(MAKE) DEBUG_LEVEL=2 TEST=$$test_name CASE_ID=$$case_id run_one_nocompile || exit $$?; \
	done

regress:
	$(MAKE) regress_dbg1
	$(MAKE) regress_dbg2
	$(MAKE) cross_validate
	$(MAKE) merge_coverage
	$(MAKE) report
	$(MAKE) unique_coverage

cross_validate:
	$(PYTHON) $(UVM_DIR)/scripts/cross_validate_dbg.py --root $(UVM_DIR)/cov_after --cases $(RDMA_SUBSYS_ALL_CASE_IDS)

merge_coverage:
	$(VCOVER) merge $(UVM_DIR)/cov_after/dbg1/BASIC_merged.ucdb $(addprefix $(UVM_DIR)/cov_after/dbg1/,$(addsuffix _s$(SEED).ucdb,$(RDMA_SUBSYS_BASIC_CASE_IDS)))
	$(VCOVER) merge $(UVM_DIR)/cov_after/dbg1/EDGE_merged.ucdb $(addprefix $(UVM_DIR)/cov_after/dbg1/,$(addsuffix _s$(SEED).ucdb,$(RDMA_SUBSYS_EDGE_CASE_IDS)))
	$(VCOVER) merge $(UVM_DIR)/cov_after/dbg1/PROF_merged.ucdb $(addprefix $(UVM_DIR)/cov_after/dbg1/,$(addsuffix _s$(SEED).ucdb,$(RDMA_SUBSYS_PROF_CASE_IDS)))
	$(VCOVER) merge $(UVM_DIR)/cov_after/dbg1/ERROR_merged.ucdb $(addprefix $(UVM_DIR)/cov_after/dbg1/,$(addsuffix _s$(SEED).ucdb,$(RDMA_SUBSYS_ERROR_CASE_IDS)))
	$(VCOVER) merge $(UVM_DIR)/cov_after/dbg2/BASIC_merged.ucdb $(addprefix $(UVM_DIR)/cov_after/dbg2/,$(addsuffix _s$(SEED).ucdb,$(RDMA_SUBSYS_BASIC_CASE_IDS)))
	$(VCOVER) merge $(UVM_DIR)/cov_after/dbg2/EDGE_merged.ucdb $(addprefix $(UVM_DIR)/cov_after/dbg2/,$(addsuffix _s$(SEED).ucdb,$(RDMA_SUBSYS_EDGE_CASE_IDS)))
	$(VCOVER) merge $(UVM_DIR)/cov_after/dbg2/PROF_merged.ucdb $(addprefix $(UVM_DIR)/cov_after/dbg2/,$(addsuffix _s$(SEED).ucdb,$(RDMA_SUBSYS_PROF_CASE_IDS)))
	$(VCOVER) merge $(UVM_DIR)/cov_after/dbg2/ERROR_merged.ucdb $(addprefix $(UVM_DIR)/cov_after/dbg2/,$(addsuffix _s$(SEED).ucdb,$(RDMA_SUBSYS_ERROR_CASE_IDS)))
	$(VCOVER) merge -combine $(UVM_DIR)/cov_after/ALL_dbg1_dbg2_merged.ucdb $(UVM_DIR)/cov_after/dbg1/BASIC_merged.ucdb $(UVM_DIR)/cov_after/dbg1/EDGE_merged.ucdb $(UVM_DIR)/cov_after/dbg1/PROF_merged.ucdb $(UVM_DIR)/cov_after/dbg1/ERROR_merged.ucdb $(UVM_DIR)/cov_after/dbg2/BASIC_merged.ucdb $(UVM_DIR)/cov_after/dbg2/EDGE_merged.ucdb $(UVM_DIR)/cov_after/dbg2/PROF_merged.ucdb $(UVM_DIR)/cov_after/dbg2/ERROR_merged.ucdb

report: generate
	$(PYTHON) /home/yifeng/.codex/skills/dv-workflow/scripts/dv_report_gen.py $(TB_DIR)
	$(PYTHON) $(UVM_DIR)/scripts/ascii_normalize_reports.py $(TB_DIR)

format_check:
	$(PYTHON) /home/yifeng/.codex/skills/dv-workflow/scripts/dv_bucket_format_check.py $(TB_DIR)
	$(PYTHON) /home/yifeng/.codex/skills/dv-workflow/scripts/bug_history_format_check.py $(TB_DIR)/BUG_HISTORY.md
	$(PYTHON) /home/yifeng/.codex/skills/dv-workflow/scripts/dv_report_format_check.py $(TB_DIR)/DV_REPORT.md
	$(PYTHON) $(UVM_DIR)/scripts/ascii_normalize_reports.py --check $(TB_DIR)

ascii_check:
	$(PYTHON) $(UVM_DIR)/scripts/ascii_normalize_reports.py --check $(TB_DIR)

unique_coverage:
	$(PYTHON) $(UVM_DIR)/scripts/check_unique_coverage.py $(TB_DIR)

clean:
	@echo "Manual cleanup required by project rule: no removal command is run by this Makefile."
