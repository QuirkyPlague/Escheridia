#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/atmosphere/distanceFog.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	
	float depth = texture(depthtex0, texcoord).r;
  vec3 LightVector=normalize(shadowLightPosition);
	vec3 worldLightVector=mat3(gbufferModelViewInverse)*LightVector;
	vec2 lightmap =texture(colortex1, texcoord).rg;
	vec4 waterMask=texture(colortex4,texcoord);
	vec4 translucentMask=texture(colortex7,texcoord);
	int blockID=int(waterMask)+100;
	bool isWater=blockID==WATER_ID;
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 sunlightColor;
	vec3 sunColor = currentSunColor(sunlightColor);
	#if DISTANCE_FOG_GLSL == 1
	vec3 mieFog = atmosphericMieFog(color.rgb, viewPos, texcoord, depth, lightmap, worldLightVector, sunColor);
	vec3 atmosphereFog = atmosphericFog(color.rgb, viewPos, texcoord, depth, lightmap);
	color.rgb = mix(atmosphereFog, mieFog, 0.4);
	#endif
}