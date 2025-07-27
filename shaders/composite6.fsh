#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	
	vec4 SpecMap = texture(colortex5, texcoord);

	float depth = texture(depthtex0, texcoord).r;
	float depth1 = texture(depthtex1, texcoord).r;
	
	if (depth == 1.0) 
	{
  		return;
	}
	vec2 lightmap =texture(colortex1, texcoord).rg;
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	
	bool isMetal = SpecMap.g >= 230.0/255.0;
	vec3 sunlightColor = vec3(0.0);
	vec3 sunColor = currentSunColor(sunlightColor);
	#if DISTANCE_FOG_GLSL == 1
	vec3 mieFog = atmosphericMieFog(color.rgb, viewPos, texcoord, depth, lightmap, worldLightVector, sunColor);
	vec3 atmosphereFog = atmosphericFog(color.rgb, viewPos, texcoord, depth, lightmap);
	vec3 fullFog = mix(atmosphereFog, mieFog, 0.4);
	
	if(isMetal)
	{
		color.rgb = mix(color.rgb, fullFog, 1.0);
	}
	
	#endif

	
	
	
}