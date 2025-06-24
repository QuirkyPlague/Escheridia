#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/brdf.glsl"
#include "/lib/blockID.glsl"

uniform sampler2D gtexture;
uniform sampler2D waterNormal;
in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 modelPos;
in vec3 viewPos;
in vec3 feetPlayerPos;
flat in int blockID;
in mat3 tbnMatrix;
/* RENDERTARGETS: 0,1,2,4,5,7,12 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 waterMask;
layout(location = 4) out vec4 specMap;
layout(location = 5) out vec4 translucentMask;
layout(location = 6) out vec4 waterNormals;


void main() {
	
	color = texture(gtexture, texcoord) * glcolor;
	if (color.a < 0.1) {
		discard;
	}
	vec3 normalMaps = texture2DLod(normals, texcoord, 0).rgb;
	normalMaps = normalMaps * 2.0 - 1.0;
	normalMaps.xy /= (254.0/255.0);
	normalMaps.z = sqrt(1.0 - dot(normalMaps.xy, normalMaps.xy));
	vec3 mappedNormal = tbnMatrix * normalMaps;

	
	waterNormals = texture(waterNormal, texcoord);
	lightmapData = vec4(lmcoord, 0.0, 1.0);
	encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);
	
	specMap = texture(specular, texcoord);
	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;

	float roughness;
 	roughness = pow(1.0 - specMap.r, 2.0);
	
	
	vec3 worldPos = cameraPosition + feetPlayerPos;
	vec3 V = normalize(cameraPosition - worldPos);
  	vec3 L = normalize(worldLightVector);
  	vec3 H = normalize(V + L);

	vec3 F0;
  	if(specMap.g <= 229.0/255.0)
  	{
    	F0 = vec3(specMap.g);
  	}
  		else
  	{
    	F0 = color.rgb;
  	}
	float emission = specMap.a;
	vec3 emissive;
	vec3 albedo = texture(colortex0,texcoord).rgb;
	if (emission >= 0.0/255.0 && emission < 255.0/255.0)
	{
		emissive += albedo * emission  * 4.0 * EMISSIVE_MULTIPLIER;
  
	}
	float sss =specMap.b;
	vec3 F=fresnelSchlick(max(dot(encodedNormal.rgb,V),0.),F0);
	vec3 shadow = getSoftShadow(shadowClipPos, feetPlayerPos, encodedNormal.rgb, texcoord, shadowScreenPos);
	
  	vec3 diffuse = doDiffuse(texcoord, lightmapData.rg, encodedNormal.rgb, worldLightVector, shadow, viewPos, sss, feetPlayerPos);
	vec3 sunlight;
	vec3 currentSunlight = getCurrentSunlight(sunlight, encodedNormal.rgb, shadow, worldLightVector);
	vec3 specular = max(brdf(albedo, F0, L, currentSunlight, encodedNormal.rgb, H, V, roughness, specMap), 0.0)  * F;
	vec3 lighting = albedo * diffuse + emissive ;
	
	if(blockID == WATER_ID)
	{
    waterMask = vec4(1.0, 1.0, 1.0, 1.0);
	waterNormals = vec4(mappedNormal * 0.5 + 0.5, 1.0);
    color.a *= 0.0;
	color = vec4(0.0);
	}
	else if(blockID == TRANSLUCENT_ID)
	{
		 translucentMask = vec4(1.0, 1.0, 1.0, 1.0);
		lighting = emissive;
	}
	else
	{
		waterMask = vec4(0.0, 0.0, 0.0, 1.0);
		translucentMask = vec4(0.0, 0.0, 0.0, 1.0);
	}


	 color = vec4(lighting, color.a);
	
	
}