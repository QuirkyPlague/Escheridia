#version 400 compatibility

#include "/lib/tonemapping.glsl"
#include "/lib/uniforms.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	
	color.rgb = lottesTonemap(color.rgb);
}