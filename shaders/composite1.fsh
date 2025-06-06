#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/SSR.glsl" 
in vec2 texcoord;


/* RENDERTARGETS: 3 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	#if GODRAYS_GLSL == 1
	float depth = texture(depthtex0, texcoord).r;
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

	color.rgb = sampleGodrays(color.rgb, texcoord, feetPlayerPos, depth);
	#endif
}