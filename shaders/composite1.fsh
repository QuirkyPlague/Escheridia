#version 410 compatibility

in vec2 texcoord;
#include "lib/atmosphere/godrays.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	color.rgb += texture(colortex9, texcoord).rgb;
}