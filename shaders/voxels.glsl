
/*
	This code is from the VOXELIZING TUTORIAL by timetravelbeard
		learn more at the links below:
			https://www.patreon.com/timetravelbeard
			https://youtube.com/@timetravelbeard3588
			https://discord.gg/S6F4r6K5yU 
			
		if you use this code as is, please leave this header. feel free to use this code in any shaders.
*/

//Voxels

#ifdef FLOODFILL
vec3 block_centered_relative_pos = feetPlayerPos + at_midBlock.xyz/64.0 +cameraPositionFract;
	ivec3 voxel_pos = ivec3(block_centered_relative_pos + VOXEL_RADIUS);


	//write voxel data
	if(mod(gl_VertexID,4)==0  //only write for 1 vertex
		&& clamp(voxel_pos,0,VOXEL_AREA) == voxel_pos //and in voxel range
	) //for one vertex per face, write if in range
	{
		//pick data to send
		
		
        vec4 voxel_data = mc_Entity.x == 10004 ? vec4(0.,1.,0.,1.) : mc_Entity.x == 10003.? vec4(1.,0.,0.,1.) : mc_Entity.x == 10005.? vec4(0.,0.,1.,1.) : vec4(0.0, 0.0, 0.0, 1.0); 
        vec4 voxel_data2 = mc_Entity.x == 10006 ? vec4(0.,1.,0.,1.) : mc_Entity.x == 10007.? vec4(1.,0.,0.,1.) : mc_Entity.x == 10008.? vec4(0.,0.,1.,1.) : vec4(0.0, 0.0, 0.0, 1.0); 
		if(at_midBlock.w > 1 && mc_Entity.x != 10004 && mc_Entity.x != 10003 && mc_Entity.x != 10005 && mc_Entity.x != 10006 && mc_Entity.x != 10007 && mc_Entity.x != 10008 ) voxel_data = vec4(1.0,0.0,0.0,1.0);

		//pack data
		uint integerValue = packUnorm4x8( voxel_data);
        uint integerValue2 = packUnorm4x8( voxel_data2);
		
		//write to 3d image	 
		//          //imageStore(  //imageAtomicMax(   are some options for writing, look up on khronos.org (opengl documentation)
		imageAtomicMax( voxelization, voxel_pos, integerValue );
        imageAtomicMax( voxelization1, voxel_pos, integerValue2 );	
    }
	#endif


