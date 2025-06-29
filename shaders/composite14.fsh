#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/bloom.glsl" 

in vec2 texcoord;

#define SCREEN_INDEX 0

/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 bloomColor;

void main() {
		Bloom screen = screens[SCREEN_INDEX];
		bloomColor = vec4(0.0, 0.0, 0.0, 1.0);
		
		vec2 tileCoord = texcoord / 2;
		
		bloomColor.rgb += upSample(colortex12, tileCoord);	
	}
