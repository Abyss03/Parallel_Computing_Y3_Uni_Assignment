﻿//reduce using local memory + accumulation of local sums into a single location
//works with any number of groups - not optimal!
__kernel void reduce_max(__global const int* A, __global int* B, __local int* scratch) {
	int id = get_global_id(0);
	int lid = get_local_id(0);
	int N = get_local_size(0);

	//cache all N values from global memory to local memory
	scratch[lid] = A[id];

	barrier(CLK_LOCAL_MEM_FENCE);//wait for all local threads to finish copying from global to local memory

	for (int i = 1; i < N; i *= 2) {
		if (!(lid % (i * 2)) && ((lid + i) < N)) 
			if (scratch[lid] < scratch[lid +i])
			{
				scratch[lid] = scratch[lid +i];
			}

		barrier(CLK_LOCAL_MEM_FENCE);
	}

	//we add results from all local groups to the first element of the array
	//serial operation! but works for any group size
	//copy the cache to output array
	if (!lid) {
		atomic_max(&B[0],scratch[lid]);
	}
}



//reduce using local memory + accumulation of local sums into a single location
//works with any number of groups - not optimal!
__kernel void reduce_min(__global const int* A, __global int* B, __local int* scratch) {
	int id = get_global_id(0);
	int lid = get_local_id(0);
	int N = get_local_size(0);

	//cache all N values from global memory to local memory
	scratch[lid] = A[id];

	barrier(CLK_LOCAL_MEM_FENCE);//wait for all local threads to finish copying from global to local memory

	for (int i = 1; i < N; i *= 2) {
		if (!(lid % (i * 2)) && ((lid + i) < N)) 
			if (scratch[lid] > scratch[lid +i])
			{
				scratch[lid] = scratch[lid +i];
			}

		barrier(CLK_LOCAL_MEM_FENCE);
	}

	//we add results from all local groups to the first element of the array
	//serial operation! but works for any group size
	//copy the cache to output array
	if (!lid) {
		atomic_min(&B[0],scratch[lid]);
	}
}



//reduce using local memory + accumulation of local sums into a single location
//works with any number of groups - not optimal!
__kernel void reduce_mean(__global const int* A, __global int* B, __local int* scratch) {
	int id = get_global_id(0);
	int lid = get_local_id(0);
	int N = get_local_size(0);

	//cache all N values from global memory to local memory
	scratch[lid] = A[id];

	barrier(CLK_LOCAL_MEM_FENCE);//wait for all local threads to finish copying from global to local memory

	for (int i = 1; i < N; i *= 2) {
		if (!(lid % (i * 2)) && ((lid + i) < N)) 
			scratch[lid] += scratch[lid + i];

		barrier(CLK_LOCAL_MEM_FENCE);
	}

	//we add results from all local groups to the first element of the array
	//serial operation! but works for any group size
	//copy the cache to output array
	if (!lid) {
		atomic_add(&B[0],scratch[lid]);
	}
}



//a very simple histogram implementation
__kernel void hist_simple(__global const int* A, __global int* H, int diff, int min, int binSize, __local int* scratch) { 

	int id = get_global_id(0);
	int lid = get_local_id(0);
	int N = get_local_size(0);

	scratch[lid] = A[id];

	barrier(CLK_LOCAL_MEM_FENCE);

	int binWidth =  diff / binSize; //finds width for each bin by taking the difference and dividing it by the number of bins

	//assumes that H has been initialised to 0
	int bin_index = (scratch[lid] + min) / binWidth; //take value as a bin index

	atomic_inc(&H[bin_index]);//serial operation, not very efficient!
	barrier(CLK_LOCAL_MEM_FENCE);
}
