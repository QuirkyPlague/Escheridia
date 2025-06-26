#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	 
	
#if GODRAYS_GLSL == 1
	color.rgb += texture(colortex3, texcoord).rgb;
	#endif
}