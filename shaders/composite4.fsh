#version 420 compatibility


#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/brdf.glsl"
in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

float depth = texture(depthtex0, texcoord).r;
  	vec3 LightVector=normalize(shadowLightPosition);
	vec3 worldLightVector=mat3(gbufferModelViewInverse)*LightVector;
	vec3 baseNormal = texture(colortex6, texcoord).rgb;
	vec3 geoNormal = normalize((baseNormal - 0.5) * 2.0); 
	vec2 lightmap =texture(colortex1, texcoord).rg;
	vec4 waterMask=texture(colortex4,texcoord);
	vec4 translucentMask=texture(colortex7,texcoord);
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
	float sss = 0.0;
	vec3 shadow = getSoftShadow(feetPlayerPos, geoNormal, sss);
	int blockID=int(waterMask)+100;
	bool isWater=blockID==WATER_ID;
	
	vec3 sunlightColor;
	vec3 sunColor = currentSunColor(sunlightColor);
	#if DISTANCE_FOG_GLSL == 1
	vec3 mieFog = atmosphericMieFog(color.rgb, viewPos, texcoord, depth, lightmap, worldLightVector, sunColor);
	vec3 atmosphereFog = atmosphericFog(color.rgb, viewPos, texcoord, depth, lightmap);
	vec3 fullFog = mix(atmosphereFog, mieFog, 0.4);
	if(!inWater)
	{
		color.rgb = mix(color.rgb, fullFog, 1.0);

	}
	#endif
	
}
