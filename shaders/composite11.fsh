#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/bloom.glsl"
#include "/lib/FXAA.glsl"

  bool inWater = isEyeInWater == 1.0;
in vec2 texcoord;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	
	 color = texture(colortex0, texcoord);
    
	#if DO_FXAA
      color.rgb = FXAA(texture(colortex0, texcoord).rgb, colortex0, texcoord);
	  
	#endif
	
}