k-Nearest Neighbor algorithm
===============
## Overview:
This project is aimed at using SDAccel to implement the k-Nearest Neighbor algorithm onto a Xilinx FPGA. The nearest neighbor algorithm is used to find the _k_ nearest neighbors of a specified point among a set of unstructured data points. It is widely used in a diverse range of domains and applications such as pattern recognition, machine learning, computer vision and coding theory to name a few. For a set _S_ of _n_ reference data points in a d-dimensional space and a query point _q_, the k-nearest neighbor algorithm finds the _k_ closest points in _S_ to the point _q_. This is illustrated in Figure 1 for k=3 and n=12. The red triangle represents the query point while the blue diamonds represent the points in the reference data set in Figure 1.
 
<center>![alt text](./figures/knn.png)</center>  
<center>Figure 1: Pictorial demonstration of KNN search algorithm</center>  

The algorithm includes the following main steps:  
1.	Compute *n* distances between the query point *q* and the *n* reference points of the set *S*. The distances in our case are the squared Euclidean distances which for a given set of two 2-dimensional points _(x<sub>1</sub>,y<sub>1</sub>)_ and _(x<sub>2</sub>,y<sub>2</sub>)_ are as follows:  
<center>_d = (x<sub>1</sub> - x<sub>2</sub>)<sup>2</sup> + (y<sub>1</sub> - y<sub>2</sub>)<sup>2</sup></center>_   
2.	Sort the _n_ distances while preserving their original indices in _S_.  
3.	Return the _k_ points from _S_ corresponding to the lowest distances of the sorted distance array.  
	
## Getting Started:
The repository contains three directories, namely "data", "knn\_cpu" and "knn\_fpga". The "data" directory contains a file with a sample set of reference data points. The "knn\_cpu" and "knn\_fpga" directories contain two different implementations of the KNN algorithm, in which the nearest neighbor identification is done on the CPU and FPGA respectively. Each implementation contains the OpenCL code of the algorithm along with the required host code and the Tcl script used to run the example in SDAccel. 
   
###File Tree  
```
KNN  
│   README.md  
│
└── data  
│   └─  filelist.txt
│
└── knn_cpu
│   │   main_cpu.cpp 
│   │   nn_cpu.cl     
│   └─  solution_cpu.tcl
│
└── knn_fpga
    │   main_fpga.cpp
    │   nn_fpga.cl
    └─  solution_fpga.tcl
```  

**File/Dir name**  | **Information**  
-------------- | -----------------  
**knn\_cpu** | Contains the "single kernel implementation" of the algorithm. The nearest neighbors identification in this implementation is done on the host.   
**knn\_fpga** | Contains the "two kernel implementation" of the algorithm, which uses a memory architecture optimization provided by SDAccel that implements the global memories used to communicate between the kernels as streaming buffers on the FPGA Block RAMs. The nearest neighbor identification in this case is done on the FPGA.  
**filelist.txt** | Contains the points of a reference data set (32768 points).  
**params.h** | Some constant parameters (see below).
**nn\_cpu.cl** | The kernel which calculates all the distances and writes them to the host for nearest neighbors identification.  
**main\_cpu.cpp** | The host code for the implementation with nearest neighbor identification done on the host.  
**nn\_cpu.cl** | The kernel which calculates all the distances and writes them to the host for nearest neighbors identification.  
**solution\_cpu.tcl**   | Script for the "single kernel implementation" in SDAccel.    
**params.h** | Some constant parameters (see below).
**main\_fpga.cpp** | The host code for the "two kernel implementation" of the algorithm, where the distances are calculated by multiple work groups in one kernel and then the neighbors are computed by a single work-group (assuming that _k_ is small) in another kernel.  
**nn\_fpga.cl** | The OpenCL code using global memory buffers to stream data between two kernels. One of the kernels calculates the distance between the query point and all the points in the reference data set. The second kernel identifies the _k_ nearest neighbors using a single work-group.  
**solution\_fpga.tcl** | Script for the "two kernel implementation" in SDAccel.    

### Parameters
The number of nearest neighbors to be returned, the required work group size and the maximum size of an input file line are defined in "params.h"
 
### How to run an example      
The code has been tested with Xilinx SDAccel 2015.1.
    
The script files for each test case can be used as follows:

>  sdaccel solution\_cpu.tcl  
>  sdaccel solution\_fpga.tcl  

The _k_ nearest neighbors, the given query point, and the total number of points are printed on standard output.

### Sample Output
The sample output after a successful run would look like:
<center>![alt text](./figures/output.png)</center>
<center>Figure 2: Sample Output after a successful run</center>  
    
## Performance Metrics
We considered the following performance metrics:
> Initiation Interval: Indicating the number of clock cycles between two consecutive iterations of a loop    
> Latency: Indicating the number of clock cycles required to complete the execution of the entire kernel

Both metrics have a profound effect on the execution time and energy consumption in case of an FPGA implementation.

### Performance Comparison
The FPGA vs GPU performance comparison for the "knn\_cpu" and "knn\_fpga" implementations in terms of execution time, power and energy consumption is described here. Note that in the "knn\_cpu" case, the nearest neighbors identification time on the host (the CPU) has also been added to the execution time. The devices used for comparison are the following:  
- NVIDIA GeForce GTX 960 with 1024 cores  
- NVIDIA Quadro K4200 with 1344 cores  
- Xilinx Virtex 7 xc7vx690tffg1157-2  

**knn\_cpu**  

Platform         |   Time       | Power(W) |  Energy(J)   
:--------------- | ------------:| --------:| ----------  
Virtex 7         |    0.587ms   |  0.412   |   0.000056  
GTX 960          |    0.528ms   |  120     |   0.00936  
K4200            |    0.603ms   |  108     |   0.0144 

Area Utilization |     Values     
:--------------- | ------------  
BRAMs            |      0   
DSPs             |      12 (0.33%)  
FFs              |      3141 (0.36%)   
LUTs             |      2042 (0.47%)  
 

**knn\_fpga**

Platform         |    Time      | Power(W) |  Energy(J)   
:--------------- | ------------:| --------:| ----------  
Virtex 7         |    1.87µs    |  3.039   |   0.0000057  
GTX 960          |    0.198ms   |  120     |   0.02376    
K4200            |    0.373ms   |  108     |   0.04028  
  

Area Utilization |     Values     
:--------------- | ------------  
BRAMs            |      32 (2.18%)   
DSPs             |      12 (0.33%)  
FFs              |      23779 (2.77%)  
LUTs             |      11595 (2.70%) 
         
## More Information
 * [SDAccel User Guide](http://www.xilinx.com/support/documentation/sw_manuals/xilinx2015_1/ug1023-sdaccel-user-guide.pdf)
 * [k-Nearest Neighbor Algorithm](https://en.wikipedia.org/wiki/K-nearest_neighbors_algorithm) 
 * [The Khronos Group Inc.](https://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/)
 * [Vivado High Level Synthesis User Guide](http://www.xilinx.com/support/documentation/sw_manuals/xilinx2015_1/ug902-vivado-high-level-synthesis.pdf)
 * [Rodinia: A benchmark Suite for Heterogeneous Computing](http://ieeexplore.ieee.org/xpls/abs_all.jsp?arnumber=5306797)  
 


 















