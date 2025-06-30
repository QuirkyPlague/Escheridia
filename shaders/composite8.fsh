#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/FXAA.glsl" 
#include "/lib/atmosphere/skyColor.glsl" 
#include "/lib/lighting/lighting.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	float depth = texture(depthtex0, texcoord).r;
	vec4 SpecMap = texture(colortex5, texcoord);
	vec3 LightVector=normalize(shadowLightPosition);
	vec3 worldLightVector=mat3(gbufferModelViewInverse)*LightVector;
	vec2 lightmap = texture(colortex1, texcoord).rg;
	vec3 sunlightColor;
	vec3 sunColor = currentSunColor(sunlightColor);
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	
	bool isMetal = SpecMap.g >= 230.0/255.0;
	
	if(depth==1.0)
	{
	
		color += texture(colortex8, texcoord) ;
		
	}
	if(isMetal)
	{
	vec3 mieFog = atmosphericMieFog(color.rgb, viewPos, texcoord, depth, lightmap, worldLightVector, sunColor);
	vec3 atmosphereFog = atmosphericFog(color.rgb, viewPos, texcoord, depth, lightmap);
	color.rgb = mix(atmosphereFog, mieFog, 0.4);
	}
	color += texture(colortex9, texcoord) * vec4(0.0667, 0.0667, 0.0667, 1.0);
	color += texture(colortex10, texcoord) * vec4(0.2235, 0.2235, 0.2235, 1.0);
}