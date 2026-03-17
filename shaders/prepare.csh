#version 430 compatibility
#include "/lib/common.glsl"

    
	layout (local_size_x = 8, local_size_y = 16, local_size_z = 1) in;



    #if VOXEL_AREA == 32
		const ivec3 workGroups = ivec3(4, 2, 32); 
	#endif
	#if VOXEL_AREA == 64
		const ivec3 workGroups = ivec3(8, 4, 64); 
	#endif
	#if VOXEL_AREA == 128
		const ivec3 workGroups = ivec3(16, 8, 128);
	#endif
    #if VOXEL_AREA == 256
		const ivec3 workGroups = ivec3(32, 16, 256);
	#endif

	layout (r32ui) uniform uimage3D voxelization;
    layout (r32ui) uniform uimage3D voxelization1;

	layout (rgba8) uniform image3D floodfill;
    layout (rgba8) uniform image3D floodfill2;

	uniform int frameCounter;
	uniform ivec3 cameraPositionInt;
	uniform ivec3 previousCameraPositionInt;

void main()
{
	#ifdef FLOODFILL
		ivec3 orig_voxel_pos =  ivec3(gl_GlobalInvocationID.xyz);
		ivec3 camshift = cameraPositionInt-previousCameraPositionInt;
		
		ivec3 voxel_pos_old = orig_voxel_pos + camshift;
		ivec3 voxel_pos_new = orig_voxel_pos;
		
		ivec3 double_buffer_offset_write = mod(frameCounter,2)==0? ivec3(0,VOXEL_AREA,0):ivec3(0);
		ivec3 double_buffer_offset_read = mod(frameCounter,2)!=0? ivec3(0,VOXEL_AREA,0):ivec3(0);
		
		voxel_pos_new+=double_buffer_offset_write;
		voxel_pos_old+=double_buffer_offset_read;
			
	
        uint integerValue = imageLoad(voxelization, orig_voxel_pos ).r;
        vec4 voxel_data = unpackUnorm4x8(integerValue); 

        uint integerValue2 = imageLoad(voxelization1, orig_voxel_pos ).r;
        vec4 voxel_data2 = unpackUnorm4x8(integerValue2); 
      
	    vec4 color_effect = voxel_data;
		vec4 color_effect2 = voxel_data2;

		
        ivec3 neighbor = ivec3(1.,0.,0.); 
        vec4 light = imageLoad(floodfill, voxel_pos_old+neighbor );  
        vec4 total_light = light-1./15.; 

        neighbor = ivec3(-1.,0.,0.);
        light = imageLoad(floodfill, voxel_pos_old+neighbor );
        total_light = max(total_light,light-1./15.);

        neighbor = ivec3(0.,1.,0.);
        light = imageLoad(floodfill, voxel_pos_old+neighbor );
        total_light = max(total_light,light-1./15.);

        neighbor = ivec3(0.,-1.,0.);
        light = imageLoad(floodfill, voxel_pos_old+neighbor );
        total_light = max(total_light,light-1./15.);

        neighbor = ivec3(0.,0.,1.);
        light = imageLoad(floodfill, voxel_pos_old+neighbor );
        total_light = max(total_light,light-1./15.);

        neighbor = ivec3(0.,0.,-1.);
        light = imageLoad(floodfill, voxel_pos_old+neighbor );
        total_light = max(total_light,light-1./15.);
        
       
        total_light= max(vec4(0.),total_light);

        color_effect = max(color_effect,total_light);

        ivec3 neighbor2 = ivec3(1.,0.,0.); //pick neighbor location
        vec4 light2 = imageLoad(floodfill2, voxel_pos_old+neighbor2 );  //load last frame data
        vec4 total_light2 = light2-1./15.; //make the effect fade over distance

        neighbor2 = ivec3(-1.,0.,0.);
        light2 = imageLoad(floodfill2, voxel_pos_old+neighbor2 );
        total_light2 = max(total_light2,light2-1./15.);

        neighbor2 = ivec3(0.,1.,0.);
        light2 = imageLoad(floodfill2, voxel_pos_old+neighbor2 );
        total_light2 = max(total_light2,light2-1./15.);

        neighbor2 = ivec3(0.,-1.,0.);
        light2 = imageLoad(floodfill2, voxel_pos_old+neighbor2 );
        total_light2 = max(total_light2,light2-1./15.);

        neighbor2 = ivec3(0.,0.,1.);
        light2 = imageLoad(floodfill2, voxel_pos_old+neighbor2 );
        total_light2 = max(total_light2,light2-1./15.);

        neighbor2 = ivec3(0.,0.,-1.);
        light2 = imageLoad(floodfill2, voxel_pos_old+neighbor2 );
        total_light2 = max(total_light2,light2-1./15.);
        
        total_light2= max(vec4(0.),total_light2);

        color_effect2 = max(color_effect2,total_light2);

   
	    imageStore(floodfill, voxel_pos_new, color_effect);
        imageStore(floodfill2, voxel_pos_new, color_effect2);

	


	#endif
} 

