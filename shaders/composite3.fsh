#version 330 compatibility

#include "/lib/util.glsl"

#include "lib/atmosphere/godrays.glsl"
in vec2 texcoord;


/* RENDERTARGETS: 7 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
    
  #if GODRAYS_ENABLE ==1
	color.rgb = sampleGodrays(color.rgb, texcoord);
	#endif
	 
}