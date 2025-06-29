#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/FXAA.glsl" 
#include "/lib/bloom.glsl" 

in vec2 texcoord;





/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	
	vec4 SpecMap = texture(colortex5, texcoord);
	vec3 bloom = texture(colortex12, texcoord).rgb;

	float roughness;
 	roughness = pow(1.0 - SpecMap.r, 2.0);

	color.rgb = computeBloomMix(texcoord);
	


	
	
	
}