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
	vec3 sunlightColor = vec3(0.0);
	vec3 sunColor = currentSunColor(sunlightColor);
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	if (depth == 1.0) 
	{
  		return;
	}
	
	bool isMetal = SpecMap.g >= 230.0/255.0;
	vec3 distanceFog = distanceFog(color.rgb, viewPos, texcoord, depth);

	color.rgb = distanceFog;
	

	color += texture(colortex9, texcoord) * vec4(0.0667, 0.0667, 0.0667, 1.0);
	color += texture(colortex10, texcoord) * vec4(0.3333, 0.3333, 0.3333, 1.0);
}