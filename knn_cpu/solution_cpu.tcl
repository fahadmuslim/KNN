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


