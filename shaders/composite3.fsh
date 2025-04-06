#version 410 compatibility

in vec2 texcoord;
#include "lib/atmosphere/godrays.glsl"

/* RENDERTARGETS: 7 */
layout(location = 0) out vec3 color;

void main() {
	#if GODRAYS_ENABLE ==1
	color = sampleGodrays(color, texcoord);
	#endif
}