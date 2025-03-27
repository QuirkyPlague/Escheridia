#version 410 compatibility

#include "/lib/util.glsl"


uniform bool horizontal;
uniform float weight[5] = float[] (0.227027 / BLOOM_STRENGTH, 0.1945946/ BLOOM_STRENGTH, 0.1216216 /BLOOM_STRENGTH , 0.054054 /BLOOM_STRENGTH , 0.016216 /BLOOM_STRENGTH);
in vec2 texcoord;



/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;


void main() {
color = texture(colortex0, texcoord);
	
}