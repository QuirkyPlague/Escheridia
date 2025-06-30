#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/FXAA.glsl" 
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"
in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	
	vec4 SpecMap = texture(colortex5, texcoord);
	vec4 waterMask=texture(colortex4,texcoord);
	int blockID=int(waterMask)+100;
	bool isWater=blockID==WATER_ID;

	float depth = texture(depthtex0, texcoord).r;
	float depth1 = texture(depthtex1, texcoord).r;
	vec3 LightVector=normalize(shadowLightPosition);
	vec3 worldLightVector=mat3(gbufferModelViewInverse)*LightVector;

	if(depth ==1)return;
	vec2 lightmap =texture(colortex1, texcoord).rg;
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	
	bool isMetal = SpecMap.g >= 230.0/255.0;

	#if DISTANCE_FOG_GLSL == 1
	if(!inWater)
	{
		//color.rgb = atmosphericFog(color.rgb, viewPos, texcoord, depth, lightmap);
	}
	
	
	if(isMetal)
	{
		color.rgb = distanceFog(color.rgb, viewPos, texcoord, depth);
	}
	
	#endif
	if(isWater && isMetal)
	{
		color.rgb += waterExtinction(color.rgb, texcoord, lightmap, depth, depth1);
	}
	
	
	
}