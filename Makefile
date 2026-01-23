MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

SOURCES = $(MAKEFILE_DIR)/src/*.vhd
TOPLEVEL = Cloneless
TOPTESTBENCH = TB_$(TOPLEVEL)_mid_pSquare_dSHARES_IPM_kRED
IOTOPLEVEL = chip_top
IOTOPTESTBENCH = TB_$(IOTOPLEVEL)_mid_pSquare_dSHARES_IPM_kRED
TESTBENCHPATH = $(MAKEFILE_DIR)/src/Testbenches
MACROPATH = $(MAKEFILE_DIR)/macros
WORKDIR = $(MAKEFILE_DIR)/work
GHDL_FLAGS = --workdir=$(WORKDIR)
GHDL_SIM_FLAGS = --stop-time=5us --ieee-asserts=disable-at-0
PDK_ROOT = $(MAKEFILE_DIR)/gf180mcu
PDK = gf180mcuD
PDK_TAG = 1.6.6
PRECHECK_ROOT = $(MAKEFILE_DIR)/gf180mcu-precheck
PRECHECK_TAG = 1.5.5
ID = G8012975

all: clean analyze sim convert sim_converted clone_pdk sim_with_io cell_replacement build_macros erase_macro_rtl build_design sim_postlayout waferspace_precheck

clean:
	rm -rf $(WORKDIR)
	rm -rf $(PDK_ROOT)
	rm -rf $(PRECHECK_ROOT)
	rm -rf $(MAKEFILE_DIR)/runs
	rm -rf $(MACROPATH)/*/runs
	rm -rf $(MAKEFILE_DIR)/*.v
	ghdl --clean
	
analyze:
	mkdir -p $(WORKDIR)
	ghdl -a $(GHDL_FLAGS) $(SOURCES)
	ghdl -a $(GHDL_FLAGS) $(TESTBENCHPATH)/$(TOPTESTBENCH).vhd
	ghdl -e $(GHDL_FLAGS) $(TOPTESTBENCH)

sim:
	ghdl -r $(GHDL_FLAGS) $(TOPTESTBENCH) $(GHDL_SIM_FLAGS)
	
convert:
	ghdl synth --out=verilog $(GHDL_FLAGS) ${TOPLEVEL} > ${TOPLEVEL}.v
	
sim_converted:
	iverilog -o $(TESTBENCHPATH)/$(TOPTESTBENCH)_verilog $(TESTBENCHPATH)/$(TOPTESTBENCH)_verilog.v ${TOPLEVEL}.v
	vvp $(TESTBENCHPATH)/$(TOPTESTBENCH)_verilog

clone_pdk:
	rm -rf $(MAKEFILE_DIR)/gf180mcu
	git clone https://github.com/wafer-space/gf180mcu.git ${PDK_ROOT} --depth 1 --branch ${PDK_TAG}
	
sim_with_io:
	iverilog -g2012 -o $(TESTBENCHPATH)/$(IOTOPTESTBENCH) $(TESTBENCHPATH)/$(IOTOPTESTBENCH).v ${PDK_ROOT}/${PDK}/libs.ref/gf180mcu_fd_io/verilog/gf180mcu_fd_io.v ${PDK_ROOT}/${PDK}/libs.ref/gf180mcu_fd_io/verilog/gf180mcu_ws_io.v $(MACROPATH)/gf180mcu_ws_ip__id/vh/gf180mcu_ws_ip__id.v $(MACROPATH)/gf180mcu_ws_ip__logo/vh/gf180mcu_ws_ip__logo.v ${TOPLEVEL}.v ${IOTOPLEVEL}.sv
	vvp $(TESTBENCHPATH)/$(IOTOPTESTBENCH)

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
	librelane $(IOTOPLEVEL).yaml --pdk ${PDK} --pdk-root ${PDK_ROOT} --manual-pdk

sim_postlayout:	
	iverilog -o $(TESTBENCHPATH)/$(IOTOPTESTBENCH) ${PDK_ROOT}/${PDK}/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/gf180mcu_fd_sc_mcu7t5v0.v ${PDK_ROOT}/${PDK}/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/primitives.v ${PDK_ROOT}/${PDK}/libs.ref/gf180mcu_fd_io/verilog/gf180mcu_fd_io.v ${PDK_ROOT}/${PDK}/libs.ref/gf180mcu_fd_io/verilog/gf180mcu_ws_io.v $(MACROPATH)/gf180mcu_ws_ip__id/vh/gf180mcu_ws_ip__id.v $(MACROPATH)/gf180mcu_ws_ip__logo/vh/gf180mcu_ws_ip__logo.v $(MACROPATH)/carry4/runs/RUN*/final/vh/carry4.vh $(MACROPATH)/ringoscillator_23/runs/RUN*/final/vh/ringoscillator_23.vh $(MACROPATH)/ringoscillator_31/runs/RUN*/final/vh/ringoscillator_31.vh $(MACROPATH)/ringoscillator_47/runs/RUN*/final/vh/ringoscillator_47.vh $(MACROPATH)/ringoscillator_59/runs/RUN*/final/vh/ringoscillator_59.vh $(MAKEFILE_DIR)/runs/RUN*/final/nl/${IOTOPLEVEL}.nl.v $(TESTBENCHPATH)/$(IOTOPTESTBENCH).v
	vvp $(TESTBENCHPATH)/$(IOTOPTESTBENCH)

waferspace_precheck:
	git clone https://github.com/wafer-space/gf180mcu-precheck --branch $(PRECHECK_TAG)
	python3 $(PRECHECK_ROOT)/precheck.py --input runs/RUN*/final/gds/$(IOTOPLEVEL).gds --top $(IOTOPLEVEL) --id $(ID)