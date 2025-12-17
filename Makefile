MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

SOURCES = $(MAKEFILE_DIR)/src/*.vhd
TOPLEVEL = Cloneless
TESTBENCH = TB_Cloneless_mid_pSquare_dSHARES_IPM_kRED
TESTBENCHPATH = $(MAKEFILE_DIR)/src/Testbenches/${TESTBENCH}
WORKDIR = $(MAKEFILE_DIR)/work
GHDL_FLAGS = --workdir=$(WORKDIR)
GHDL_SIM_FLAGS = --stop-time=5us --ieee-asserts=disable-at-0

PDK_ROOT ?= $(MAKEFILE_DIR)/gf180mcu
PDK ?= gf180mcuD
PDK_TAG ?= 1.6.6

all: clean analyze sim convert sim_converted cell_replacement clone_pdk build_macros erase_macro_rtl build_design

clean:
	rm -rf $(WORKDIR)
	rm -rf $(PDK_ROOT)
	rm -rf runs
	rm -rf *.v
	ghdl --clean
	
analyze:
	mkdir -p $(WORKDIR)
	ghdl -a $(GHDL_FLAGS) $(SOURCES)
	ghdl -a $(GHDL_FLAGS) $(TESTBENCHPATH).vhd
	ghdl -e $(GHDL_FLAGS) $(TESTBENCH)

sim:
	ghdl -r $(GHDL_FLAGS) $(TESTBENCH) $(GHDL_SIM_FLAGS)
	
convert:
	ghdl synth --out=verilog $(GHDL_FLAGS) ${TOPLEVEL} > ${TOPLEVEL}.v
	
sim_converted:
	iverilog -o $(TESTBENCHPATH)_verilog $(TESTBENCHPATH)_verilog.v ${TOPLEVEL}.v
	vvp $(TESTBENCHPATH)_verilog
	
cell_replacement:
	sed -z -i 's/module inv.*i;\nendmodule\n\n//g' ${TOPLEVEL}.v
	sed -z -i 's/module mux2.*i1;\nendmodule\n\n//g' ${TOPLEVEL}.v
	sed -z -i 's/module nand2.*a2);\nendmodule\n\n//g' ${TOPLEVEL}.v
	sed -z -i 's/module xor2.*a2;\nendmodule\n\n//g' ${TOPLEVEL}.v
	sed -i 's/  inv /(* keep = "true" *) gf180mcu_fd_sc_mcu7t5v0__inv_1 /g' ${TOPLEVEL}.v
	sed -i 's/  mux2 /(* keep = "true" *) gf180mcu_fd_sc_mcu7t5v0__mux2_1 /g' ${TOPLEVEL}.v
	sed -i 's/  nand2 /(* keep = "true" *) gf180mcu_fd_sc_mcu7t5v0__nand2_1 /g' ${TOPLEVEL}.v
	sed -i 's/  xor2 /(* keep = "true" *) gf180mcu_fd_sc_mcu7t5v0__xor2_1 /g' ${TOPLEVEL}.v
	sed -i 's/\.i(/\.I(/g' ${TOPLEVEL}.v
	sed -i 's/\.zn(/\.ZN(/g' ${TOPLEVEL}.v
	sed -i 's/\.i0(/\.I0(/g' ${TOPLEVEL}.v
	sed -i 's/\.i1(/\.I1(/g' ${TOPLEVEL}.v
	sed -i 's/\.s(/\.S(/g' ${TOPLEVEL}.v
	sed -i 's/\.z(/\.Z(/g' ${TOPLEVEL}.v
	sed -i 's/\.a1(/\.A1(/g' ${TOPLEVEL}.v
	sed -i 's/\.a2(/\.A2(/g' ${TOPLEVEL}.v
	sed -i 's/(input/(\n   `ifdef USE_POWER_PINS\n   inout wire VSS,\n   inout wire VDD,\n   `endif\n   input/g' ${TOPLEVEL}.v
	sed -z -i 's/(\n    \./(\n    `ifdef USE_POWER_PINS\n    \.VSS(VSS),\n    \.VDD(VDD),\n    `endif\n    \./g' ${TOPLEVEL}.v

clone_pdk:
	rm -rf $(MAKEFILE_DIR)/gf180mcu
	git clone https://github.com/wafer-space/gf180mcu.git ${PDK_ROOT} --depth 1 --branch ${PDK_TAG}
	
build_macros:
	librelane macros/carry4/carry4.yaml --pdk ${PDK} --pdk-root ${PDK_ROOT} --manual-pdk
	librelane macros/ringoscillator_23/ringoscillator_23.yaml --pdk ${PDK} --pdk-root ${PDK_ROOT} --manual-pdk
	librelane macros/ringoscillator_31/ringoscillator_31.yaml --pdk ${PDK} --pdk-root ${PDK_ROOT} --manual-pdk
	librelane macros/ringoscillator_47/ringoscillator_47.yaml --pdk ${PDK} --pdk-root ${PDK_ROOT} --manual-pdk
	librelane macros/ringoscillator_59/ringoscillator_59.yaml --pdk ${PDK} --pdk-root ${PDK_ROOT} --manual-pdk
	
erase_macro_rtl:
	sed -z -i 's/module carry4.*x1_n8813};\nendmodule\n\n//g' ${TOPLEVEL}.v
	sed -z -i 's/module ringoscillator_59.*nd_n8616};\nendmodule\n\n//g' ${TOPLEVEL}.v
	sed -z -i 's/module ringoscillator_47.*nd_n8377};\nendmodule\n\n//g' ${TOPLEVEL}.v
	sed -z -i 's/module ringoscillator_31.*nd_n8125};\nendmodule\n\n//g' ${TOPLEVEL}.v
	sed -z -i 's/module ringoscillator_23.*nd_n7998};\nendmodule\n\n//g' ${TOPLEVEL}.v
	
build_design:
	librelane chip_top.yaml --pdk ${PDK} --pdk-root ${PDK_ROOT} --manual-pdk