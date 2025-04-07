#version 410 compatibility

in vec2 texcoord;
#include "lib/atmosphere/godrays.glsl"

/* RENDERTARGETS: 7 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	#if GODRAYS_ENABLE ==1
	color.rgb += sampleGodrays(color.rgb, texcoord);
	#endif
}