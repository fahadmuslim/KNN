/* 
======================================================
 Copyright 2016 Fahad Bin Muslim
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at
       http://www.apache.org/licenses/LICENSE-2.0
   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
======================================================
*
* Author:   Fahad Bin Muslim (fahad.muslim@polito.it)
*
* Tcl script to run the knn_cpu implementation on an FPGA.
*
*----------------------------------------------------------------------------
*/
# SDAccel command script

# Define a solution name
create_solution -name solution_cpu -dir . -force

# Define the target platform of the application
add_device -vbnv xilinx:adm-pcie-7v3:1ddr:2.0

# Host source files
add_files "main_cpu.cpp"

# Kernel definition
create_kernel NearestNeighbor -type clc
add_files -kernel [get_kernels NearestNeighbor] "nn_cpu.cl"

# Define binary containers
create_opencl_binary nn
set_property region "OCL_REGION_0" [get_opencl_binary nn]
create_compute_unit -opencl_binary [get_opencl_binary nn] -kernel [get_kernels NearestNeighbor] -name K1

# Compile the design for CPU based emulation
compile_emulation -flow cpu -opencl_binary [get_opencl_binary nn]

# Generate the system estimate report
report_estimate

# Run the design in CPU emulation mode
run_emulation -flow cpu -args "nn.xclbin"

# Build the application for hardware
build_system

# Package the results for the card
package_system


