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
* All constants used in this implementation defined here.
*
*----------------------------------------------------------------------------
*/
#define NUM_NEIGHBORS 5 // number of neighbors to be returned
#define WORK_GROUP_SIZE 256
#define GLOBAL_SIZE 294912 // size of global memory buffer
#define REC_LENGTH 49 // size of a record in the input file
#define QUERY_LAT 30.0 // query point latitude
#define QUERY_LNG 90.0 // query point longitude
