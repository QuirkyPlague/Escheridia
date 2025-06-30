#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/bloom.glsl" 

in vec2 texcoord;


/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 bloomColor;

void main() {
		#if BLOOM_GLSL ==1
		bloomColor = vec4(0.0, 0.0, 0.0, 1.0);
		bloomColor.rgb = upSample(colortex12, texcoord / 2);	
		#endif
	}
