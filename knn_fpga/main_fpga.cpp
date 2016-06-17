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
* This is the host code for communicating with the FPGA to calculate the 
* distances between the query point and all the points in reference data set.
* The neighbors identification is done on FPGA as well.
* It then reads the neighbors alongwith their locations from the FPGA.
*
*----------------------------------------------------------------------------
*/
#include <iostream>
#include <vector>
#include <float.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <CL/opencl.h>
#include <algorithm>
#include "params.h"

#define CL_USE_DEPRECATED_OPENCL_1_1_APIS //to solve compatibility issues b/w various OCL libraries

typedef struct record
{
  char recString[REC_LENGTH];
  float distance;
} Record;

void findLowest(std::vector<Record> &records,float *distances,int *minLocations,int topN) {
  int i;
  float val;
  int minLoc1;
  Record *tempRec;
  
  for(i=0;i<topN;i++) {
    minLoc1 = minLocations[i];
   
    // swap locations 
    tempRec = &records[i];
    records[i] = records[minLoc1];
    records[minLoc1] = *tempRec;
    
    // add distance to the min we found
    records[i].distance = distances[i];
  }
}

int load_file_to_memory(const char *filename, char **result) { 
  size_t size = 0;
  FILE *f = fopen(filename, "rb");
  if (f == NULL) 
  { 
    *result = NULL;
    return -1; // -1 means file opening fail 
  } 
  fseek(f, 0, SEEK_END);
  size = ftell(f);
  fseek(f, 0, SEEK_SET);
  *result = (char *)malloc(size+1);
  if (size != fread(*result, sizeof(char), size, f)) 
  { 
    free(*result);
    return -2; // -2 means file reading fail 
  } 
  fclose(f);
  (*result)[size] = 0;
  return size;
}

int main(int argc, char *argv[]) {
  std::vector<Record> records;
  std::vector<cl_float2> locations;
  int i;
  char filename[1024];
  int resultsCount=NUM_NEIGHBORS,quiet=0;
  float lat=QUERY_LAT,lng=QUERY_LNG;
  
  cl_context context;
  cl_context_properties properties[3];
  cl_kernel kernel1;
  cl_kernel kernel2;
  cl_command_queue command_queue;
  cl_program program;
  cl_int err;
  cl_uint num_of_platforms=0;
  cl_platform_id platform_id;
  cl_device_id device_id;
  cl_uint num_of_devices=0;

  FILE *fp;
  int numRecords=0;
  fp = fopen("../../../../../data/filelist.txt", "r");
  if(!fp) {
    perror("error opening the data file\n");
    exit(1);
  }
        // read each record
  while(!feof(fp)){
    Record record;
    cl_float2 latLong;
    fgets(record.recString,REC_LENGTH,fp);
    fgetc(fp); // newline
    if (feof(fp)) break;
            
    // parse for lat and long
    char str[REC_LENGTH];
    strncpy(str,record.recString,sizeof(str));
    int year, month, date, hour, num, speed, press;
    float lat, lon;
    char name[REC_LENGTH];
    sscanf(str, "%d %d %d %d %d %s %f %f %d %d", &year, 
      &month, &date, &hour, &num, name, &lat,   &lon, &speed, &press);    
    latLong.x = lat;
    latLong.y = lon;   

    locations.push_back(latLong);
    records.push_back(record);
    numRecords++;
  }
  fclose(fp);


  if (!quiet) {
    printf("Number of points in reference data set: %d\n",numRecords);
    printf("latitude: %f\n",lat);
    printf("longitude: %f\n",lng);
    printf("Finding the %d closest neighbors.\n",resultsCount);
  }

  if (resultsCount > numRecords) resultsCount = numRecords;

  // retreive a list of platforms avaible
  if (clGetPlatformIDs(1, &platform_id, &num_of_platforms)!= CL_SUCCESS) {
    printf("Unable to get platform_id\n");
    return 1;
  }

  // connect to a compute device	
  if (clGetDeviceIDs(platform_id, CL_DEVICE_TYPE_ACCELERATOR, 1, 
    &device_id, &num_of_devices) != CL_SUCCESS) {
    printf("Unable to get device_id\n");
    return 1;
  }

  // context properties list - must be terminated with 0
  properties[0]= CL_CONTEXT_PLATFORM;
  properties[1]= (cl_context_properties) platform_id;
  properties[2]= 0;

  // create a context with the FPGA device
  context = clCreateContext(properties,1,&device_id,NULL,NULL,&err);

  // create command queue using the context and device
  command_queue = clCreateCommandQueue(context, device_id, 0, &err);

  int status;
  unsigned char *kernelbinary;
  char *xclbin=argv[1];
  printf("loading %s\n", xclbin);
  int n_i = load_file_to_memory(xclbin, (char **) &kernelbinary);
  if (n_i < 0) {
    printf("failed to load kernel from xclbin: %s\n", xclbin);
    printf("Test failed\n");
    return EXIT_FAILURE;
  }
  size_t n = n_i;

  // Create the compute program from offline
  program = clCreateProgramWithBinary(context, 1, &device_id, &n,
    (const unsigned char **) &kernelbinary, &status, &err);

  // compile the program
  if (clBuildProgram(program, 0, NULL, NULL, NULL, NULL) != CL_SUCCESS) {
    printf("Error building program\n");
    return 1;
  }

  // specify which kernel from the program to execute
  kernel1 = clCreateKernel(program, "distance_calc", &err);
  kernel2 = clCreateKernel(program, "NearestNeighbor", &err);
 
  // create buffers for the input and ouput
  cl_mem d_locations;
  cl_mem d_distances;
  cl_mem indices;

  d_locations = clCreateBuffer(context, CL_MEM_READ_ONLY,
    sizeof(cl_float2) * numRecords, NULL, NULL);
  d_distances = clCreateBuffer(context, CL_MEM_WRITE_ONLY,
    sizeof(float) * resultsCount, NULL, NULL);
  indices = clCreateBuffer(context, CL_MEM_WRITE_ONLY, 
    sizeof(int) * resultsCount, NULL, NULL); 
    
  // load data into the input buffer
  clEnqueueWriteBuffer(command_queue, d_locations, CL_TRUE, 0, 
    sizeof(cl_float2) * numRecords, &locations[0], 0, NULL, NULL);

  // set the argument list for the kernel1 command
  clSetKernelArg(kernel1, 0, sizeof(cl_mem), (void *)&d_locations);
  clSetKernelArg(kernel1, 1, sizeof(float), (void *)&lat);
  clSetKernelArg(kernel1, 2, sizeof(float), (void *)&lng);
     
  // enqueue kernel for execution
  size_t globalWorkSize1[1];
  size_t local1[1];
  local1[0] = WORK_GROUP_SIZE;
  globalWorkSize1[0] = numRecords;//Total number of work items to execute a kernel
    
  clEnqueueNDRangeKernel(command_queue, kernel1, 1, NULL, 
    (size_t*)&globalWorkSize1, (size_t*)&local1, 0, NULL, NULL);
    
  // set the argument list for the kernel2 command
  clSetKernelArg(kernel2, 0, sizeof(cl_mem), (void *)&d_distances); 
  clSetKernelArg(kernel2, 1, sizeof(cl_mem), (void *)&indices);
  clSetKernelArg(kernel2, 2, sizeof(int), (void *)&numRecords);
  clSetKernelArg(kernel2, 3, sizeof(int), (void *)&resultsCount);
     
  // enqueue kernel for execution
  size_t globalWorkSize2[1];
  size_t local2[1];
  local2[0] = WORK_GROUP_SIZE;
  globalWorkSize2[0] = numRecords;//Total number of work items to execute a kernel
    
  clEnqueueNDRangeKernel(command_queue, kernel2, 1, NULL, 
    (size_t*)&globalWorkSize2, (size_t*)&local2, 0, NULL, NULL);
  
  // transfer the results from the output buffer
  float *distances = (float *)malloc(sizeof(float) * resultsCount);
  int *minLocations_final = (int *)malloc(sizeof(int) * resultsCount);

  clEnqueueReadBuffer(command_queue, d_distances, CL_TRUE, 0, 
    sizeof(float) * resultsCount, distances, 0, NULL, NULL);
  clEnqueueReadBuffer(command_queue, indices, CL_TRUE, 0, 
    sizeof(int) * resultsCount, minLocations_final, 0, NULL, NULL);

  // return finalized data and release buffers
  clReleaseMemObject(d_locations);
  clReleaseMemObject(d_distances);
  clReleaseMemObject(indices);
  clReleaseProgram(program);
  clReleaseKernel(kernel1);
  clReleaseKernel(kernel2);
  clReleaseCommandQueue(command_queue);
  clReleaseContext(context);

  // find the resultsCount least distances
  findLowest(records,distances,minLocations_final,resultsCount);

  // print out results
  if (!quiet)
    for(i=0;i<resultsCount;i++) {
      printf("%s --> Distance=%f\n",records[i].recString,records[i].distance);
    }
  return 0;
}

