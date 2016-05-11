#define WORK_GROUP_SIZE 256
#define GLOBAL_SIZE 32768
global float dist[GLOBAL_SIZE]; //on-chip global buffer

__kernel __attribute__ ((reqd_work_group_size(WORK_GROUP_SIZE, 1, 1)))
void distance_calc(__global float2 *d_locations,
                     const float lat,
		     const float lng) {
  local float lat_local[WORK_GROUP_SIZE];
  local float lng_local[WORK_GROUP_SIZE];
  __attribute__((xcl_pipeline_workitems)) {

  int localId = get_local_id(0);
  int globalId = get_global_id(0);
  float dist_lat, dist_lng;

  lat_local[localId] = d_locations[globalId].x;
  lng_local[localId] = d_locations[globalId].y;

  dist_lat = lat-lat_local[localId];
  dist_lng = lng-lng_local[localId];

  //squared euclidean distance calculation
  dist[globalId] = (dist_lat*dist_lat) + (dist_lng*dist_lng);
  }
}

__kernel __attribute__ ((reqd_work_group_size(WORK_GROUP_SIZE,1,1)))
void NearestNeighbor (__global float *d_distances,
                      __global int *indices,
                      const int resultsCount) {
  int localId = get_local_id(0);
  if (localId < 5) {
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
  indices[localId] = index1;}
  } 
} 
