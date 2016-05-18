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
* The kernel to calculate the distances between the    
* query point and all the points in reference data set.
*
*----------------------------------------------------------------------------
*/
#include "params.h"

// This computes the distance of all points in d_locations from the given 
// longitude and latitude, and returns it in d_distances.
__kernel __attribute__ ((reqd_work_group_size(WORK_GROUP_SIZE , 1, 1)))
void NearestNeighbor(__global float2 *d_locations,
		     __global float *d_distances,
                       const float lat,
		       const float lng) {
  __attribute__((xcl_pipeline_workitems)) {

  int globalId = get_global_id(0);
  float lat_tmp,lng_tmp,dist_lat,dist_lng;

  // using temporaries for the latitude and longitude
  lat_tmp = d_locations[globalId].x;
  lng_tmp = d_locations[globalId].y;

  dist_lat = lat-lat_tmp;
  dist_lng = lng-lng_tmp;

  // squared euclidean distance
  d_distances[globalId] = (dist_lat*dist_lat) + (dist_lng*dist_lng);
  }
}
