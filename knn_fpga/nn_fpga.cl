#define WORK_GROUP_SIZE 256
#define GLOBAL_SIZE 32768
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
  int localId = get_local_id(0);
  if (localId < resultsCount) {
    int index1 = localId;
    float val,tempDist;
    __attribute__((xcl_pipeline_loop))
    for (int k=localId; k < WORK_GROUP_SIZE; k++) {
      val = dist[k];
      if (val < dist[index1]) index1 = k;
    }

    // swap distances 
    tempDist = dist[localId];
    dist[localId] = dist[index1];
    dist[index1] = tempDist;
  
    // first WG used to ensure that the indices of the neighbors are preserved       
    if (get_group_id(0)==0) {
      d_distances[localId] = dist[localId];
      indices[localId] = index1;
    }
  } 
} 
