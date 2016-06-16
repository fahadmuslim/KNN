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
* This OpenCL code has a kernel to calculate the distances     
* between the query point and all the points in reference data set.
* A second kernel is used to identify the nearest neighbors.  
* 
*----------------------------------------------------------------------------
*/
#include "params.h"

global float dist[GLOBAL_SIZE]; //on-chip global buffer

// This computes the distance of all points in d_locations from the given 
// longitude and latitude, and returns it in the on-chip global buffer
// dist.
__kernel __attribute__ ((reqd_work_group_size(WORK_GROUP_SIZE, 1, 1)))
void distance_calc(__global float2 *d_locations,
                     const float lat,
		     const float lng) {
__attribute__((xcl_pipeline_workitems)) {

  int globalId = get_global_id(0);
  float lat_tmp, lng_tmp, dist_lat, dist_lng;

  // using temporaries for the latitude and longitude
  lat_tmp = d_locations[globalId].x;
  lng_tmp = d_locations[globalId].y;

  dist_lat = lat-lat_tmp;
  dist_lng = lng-lng_tmp;

  //squared euclidean distance calculation
  dist[globalId] = (dist_lat*dist_lat) + (dist_lng*dist_lng);
}
}

// This computes the resultsCount nearest neighbors, one per work item.
__kernel __attribute__ ((reqd_work_group_size(WORK_GROUP_SIZE,1,1)))
void NearestNeighbor (__global float *d_distances,
                      __global int *indices,
                        const int resultsCount) {
  __local float dmin1; 
  int localId = get_local_id(0);
  if (localId < resultsCount) {
      float dist1;
      float dmin = MAXFLOAT;
      int count = 0;

      if (localId == 0) {
	  dmin1 = 0.0f;
      }
     
      __attribute__((xcl_pipeline_loop))
      for (int k = 0; k < WORK_GROUP_SIZE; k++) {
	  dist1 = dist[k];
	  if (dist1 < dmin && dist1 > dmin1) {
	      dmin = dist1;
	      count = k;
	  }
	  if (k == WORK_GROUP_SIZE-1) {
	      dmin1 = dmin;
	      indices[localId] = count;
	      d_distances[localId] = dmin;
	  }
      }
  } 
}

