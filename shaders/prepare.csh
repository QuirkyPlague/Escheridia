#version 430 compatibility
#include "/lib/common.glsl"

layout(local_size_x=8,local_size_y=16,local_size_z=1)in;

#if VOXEL_AREA==32
const ivec3 workGroups=ivec3(4,2,32);
#endif
#if VOXEL_AREA==64
const ivec3 workGroups=ivec3(8,4,64);
#endif
#if VOXEL_AREA==128
const ivec3 workGroups=ivec3(16,8,128);
#endif
#if VOXEL_AREA==256
const ivec3 workGroups=ivec3(32,16,256);
#endif

layout(r32ui)uniform uimage3D voxelization;
layout(r32ui)uniform uimage3D voxelization1;

layout(rgba8)uniform image3D floodfill;


uniform int frameCounter;
uniform ivec3 cameraPositionInt;
uniform ivec3 previousCameraPositionInt;

void main()
{
    #ifdef FLOODFILL
    ivec3 orig_voxel_pos=ivec3(gl_GlobalInvocationID.xyz);
    ivec3 camshift=cameraPositionInt-previousCameraPositionInt;
    
    ivec3 voxel_pos_old=orig_voxel_pos+camshift;
    ivec3 voxel_pos_new=orig_voxel_pos;
    
    ivec3 double_buffer_offset_write=mod(frameCounter,2)==0?ivec3(0,VOXEL_AREA,0):ivec3(0);
    ivec3 double_buffer_offset_read=mod(frameCounter,2)!=0?ivec3(0,VOXEL_AREA,0):ivec3(0);
    
    voxel_pos_new+=double_buffer_offset_write;
    voxel_pos_old+=double_buffer_offset_read;
    
    uint integerValue=imageLoad(voxelization,orig_voxel_pos).r;
    vec4 voxel_data=unpackUnorm4x8(integerValue);
    
 
    
    vec3 lightRGB = voxel_data.r*vec3(1.614, 1.4745, 1.3373) * 0.5 + voxel_data.g*vec3(0.4627, 0.8275, 1.0)  + voxel_data.b*vec3(0.9137, 0.9686, 1.0);
  

    ivec3 neighbor=ivec3(1.,0.,0.);
    vec3 totalLight=vec3(0.);
    vec3 totalLight2=vec3(0.);

    ivec3 offsets[6]=ivec3[6](
        ivec3(1,0,0),ivec3(-1,0,0),
        ivec3(0,1,0),ivec3(0,-1,0),
        ivec3(0,0,1),ivec3(0,0,-1)
    );
    
    for(int i=0;i<6;i++)
    {
        vec3 neighborLight=imageLoad(floodfill,voxel_pos_old+offsets[i]).rgb;
      

        totalLight=max(totalLight,neighborLight-vec3(1./15.));
        
    }
    
    lightRGB=max(lightRGB,totalLight);

    
    imageStore(floodfill,voxel_pos_new,vec4(lightRGB,1.));
    
    
    #endif
}

