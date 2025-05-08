#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/bloom.glsl"


in vec2 texcoord;
 vec4 waterMask = texture(colortex8, texcoord);
  int blockID = int(waterMask) + 100;
  
  bool isWater = blockID == WATER_ID;
 bool inWater = isEyeInWater == 1.0;
/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 color;


void main() {
	 color = texture(colortex0, texcoord);
   #if DO_BLOOM == 1
     color.rgb += downsampleScreen(colortex5,texcoord);
   #endif
}