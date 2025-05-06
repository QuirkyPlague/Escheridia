#version 330 compatibility

#include "/lib/util.glsl"
in vec2 texcoord;

 float exposure = BLOOM_INTENSITY;
bool inWater = isEyeInWater == 1.0;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;


void main() {
	color = texture(colortex0, texcoord);
   
}