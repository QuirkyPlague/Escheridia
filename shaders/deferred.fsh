#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/brdf.glsl"
in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	float depth = texture(depthtex0, texcoord).r;
	if (depth == 1.0) 
	{
  		return;
	}
	
	vec4 SpecMap = texture(colortex5, texcoord);
	vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components
	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
vec3 baseNormal = texture(colortex6, texcoord).rgb;
	vec3 geoNormal = normalize((baseNormal - 0.5) * 2.0); 
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 worldPos = cameraPosition + feetPlayerPos;
	
	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
	
	vec3 shadow = getSoftShadow(shadowClipPos, feetPlayerPos, geoNormal, texcoord, shadowScreenPos);
	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

	float roughness;
 	roughness = pow(1.0 - SpecMap.r, 2.0);
	
	float emission = SpecMap.a;
	vec3 emissive;
	vec3 albedo = texture(colortex0,texcoord).rgb;
	if (emission >= 0.0/255.0 && emission < 255.0/255.0)
	{
		emissive += albedo * emission * 2.5 * EMISSIVE_MULTIPLIER;
  
	}

	vec3 V = normalize(cameraPosition - worldPos);
  	vec3 L = normalize(worldLightVector);
  	vec3 H = normalize(V + L);
	float ao = normal.b;
	vec3 F0;
  	if(SpecMap.g <= 229.0/255.0)
  	{
    	F0 = vec3(SpecMap.g);
  	}
  		else
  	{
    	F0 = albedo;
  	}
	bool isMetal = SpecMap.g >= 230.0/255.0;
	vec3 diffuse = doDiffuse(texcoord, lightmap, normal, worldLightVector, shadow, viewPos);
	vec3 sunlight;
	vec3 currentSunlight = getCurrentSunlight(sunlight, normal, shadow, worldLightVector);
	vec3 specular = brdf(albedo, F0, L, currentSunlight, normal, H, V, roughness, SpecMap) ;
	vec3 lighting = albedo * diffuse + specular + emissive;
	
	#if LIGHTING_GLSL == 1
	color.rgb = lighting;
	#endif
	
}