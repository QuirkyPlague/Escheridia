#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/brdf.glsl"
#include "/lib/blockID.glsl"

uniform sampler2D gtexture;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 modelPos;
in vec3 viewPos;
in vec3 feetPlayerPos;
flat in int blockID;
in mat3 tbnMatrix;
/* RENDERTARGETS: 0,1,2,4,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 waterMask;
layout(location = 4) out vec4 specMap;
void main() {
	color = texture(gtexture, texcoord) * glcolor;
	
	if (color.a < 0.1) {
		discard;
	}

	if(blockID == WATER_ID)
	{
    waterMask = vec4(1.0, 1.0, 1.0, 1.0);
    color.a *= 0.1;
	}
	else
	{
		waterMask = vec4(0.0, 0.0, 0.0, 1.0);
	}

	vec3 normalMaps = texture(normals, texcoord).rgb;
	normalMaps = normalMaps * 2.0 - 1.0;
	normalMaps.z = sqrt(1.0 - dot(normalMaps.xy, normalMaps.xy));
	vec3 mappedNormal = tbnMatrix * normalMaps;


	lightmapData = vec4(lmcoord, 0.0, 1.0);
	encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);
	specMap = texture(specular, texcoord);
	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);

	float roughness;
 	roughness = pow(1.0 - specMap.r, 2.0);
	
	float emission = specMap.a;
	vec3 emissive;
	if (emission >= 0.0/255.0 && emission < 255.0/255.0)
	{
		emissive += color.rgb * emission  * 5.0 * EMISSIVE_MULTIPLIER;
  
	}
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

	
	vec3 shadow = getSoftShadow(shadowClipPos, feetPlayerPos, encodedNormal.rgb);
  	vec3 diffuse = doDiffuse(texcoord, lightmapData.rg, encodedNormal.rgb, worldLightVector, shadow);
	vec3 sunlight;
	vec3 currentSunlight = getCurrentSunlight(sunlight, encodedNormal.rgb, shadow, worldLightVector);
	vec3 specular = brdf(color.rgb, F0, L, currentSunlight, normal, H, V, roughness, specMap);
	vec3 lighting = color.rgb * diffuse + specular + emissive;
	color = vec4(lighting, color.a);

}