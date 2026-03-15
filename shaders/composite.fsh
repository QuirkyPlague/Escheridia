#version 430 compatibility


#include "/lib/uniforms.glsl"


in vec2 texcoord;


//set the voxelizing distance that isn't culled off-screen
#if VOXEL_AREA == 32
	const float voxelDistance = 32.0;
#endif
#if VOXEL_AREA == 64
	const float voxelDistance = 64.0;
#endif
#if VOXEL_AREA == 128
	const float voxelDistance = 128.0;
#endif
#if VOXEL_AREA == 256
	const float voxelDistance = 256.0;
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;
void main() {
  //assign colortex buffers
  color = texture(colortex0, texcoord);
 
}


