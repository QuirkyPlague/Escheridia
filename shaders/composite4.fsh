#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/brdf.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"
in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	float depth = texture(depthtex0, texcoord).r;
	if (depth == 1.0) return;

	//buffer assignments
	vec4 SpecMap = texture(colortex5, texcoord);
	vec3 albedo = texture(colortex0, texcoord).rgb;
	vec3 encodedNormal = texture(colortex2,texcoord).rgb;
	vec4 sssMask = texture(colortex11, texcoord);
	vec4 waterMask=texture(colortex4,texcoord);
	vec4 translucentMask=texture(colortex7,texcoord);
	
	//block IDs
	int blockID=int(waterMask)+100;
	int blockID2=int(translucentMask)+102;
	int blockID3=int(sssMask)+103;

	//bools
	bool canScatter = blockID3 == SSS_ID;
	bool isTranslucent=blockID2==TRANSLUCENT_ID;
	bool isWater=blockID==WATER_ID;
	bool isMetal = SpecMap.g >= 230.0/255.0;

	//normal assignments
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
	vec3 baseNormal = texture(colortex6, texcoord).rgb;
	vec3 geoNormal = normalize((baseNormal - 0.5) * 2.0); 
	
	//space conversions
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 worldPos = cameraPosition + feetPlayerPos;
	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
	
	float sss;
	#if RESOURCE_PACK_SUPPORT == 1
	if(canScatter)
	{sss = 1.0;}
	else
	{sss = 0.0;}
	#else
	sss = SpecMap.b;
	#endif

	//sun and shadow
	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
	vec3 shadow = getSoftShadow(shadowClipPos, geoNormal, sss);

	float roughness;
 	roughness = pow(1.0 - SpecMap.r, 2.0);
	
	if(isWater)
	{roughness = 0.05;}

	vec3  f0;
	if(isMetal)
  	{f0 = albedo;}
	else if(isWater)
	{f0 = vec3(0.02);}
	else
	{f0 = vec3(SpecMap.g);}

	vec3 V = normalize(cameraPosition - worldPos);
  	vec3 L = normalize(worldLightVector);
  	vec3 H = normalize(V + L);

	vec3 sunlight;
	vec3 currentSunlight = getCurrentSunlight(sunlight, normal, shadow, worldLightVector, sss, feetPlayerPos);
	
	vec3 specular = brdf(albedo, f0, L, currentSunlight, normal, H, V, roughness, SpecMap);
	
	color.rgb += specular;
	
}
/*
if(isMetal && SpecMap.r < 155.0/255.0 )
	{
		vec3 skyMieReflection = calcMieSky(normalize(viewPos), worldLightVector, sunColor, viewPos) * 1.7;
		vec3 skyReflection =calcSkyColor((reflect(normalize(viewPos),n2)));
		reflectedColor= mix(skyReflection, skyMieReflection, 0.6);
		reflectedColor *= lightmap.g;
		reflectedColor *= 0.4;
		if(lightmap.g < 0.55)
		{
			reflectedColor = color.rgb;
		}
	}
if(isRaining)
	{
		float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
		float currentRoughness = roughness;
		float wetRoughness = 0.15;
		
		roughness = mix(currentRoughness, wetRoughness, dryToWet);
		if(lightmap.g < 0.8785)
		{ 
			float reflectedColorFalloff = exp2(5.0 * (0.64 - lightmap.g));
			currentRoughness = pow(1.0 - SpecMap.r, 2.0);
			roughness = mix(wetRoughness , currentRoughness, clamp(reflectedColorFalloff, 0, 1) );
		
		}
	}
	
	#if DO_SSR == 1
	if(roughness <= 0.31 && isRaining && !isMetal && SpecMap.r <= 155.0/255.0 && !isWater)
	{
		
		reflectedColor = texture(colortex0, reflectedPos.xy).rgb;
		
		if(clamp(reflectedPos.xy, -1.0, 1.0) != reflectedPos.xy)
			{
				
			 reflectedColor=calcSkyColor((reflect(normalize(viewPos),n2)));
				reflectedColor * lightmap.g;
			}
		if(lightmap.g < 0.9935)
		{ 
			float reflectedColorFalloff = exp(-5.512 * (1.214 - lightmap.g));
			vec3 reflectedSkyColor = calcSkyColor((reflect(normalize(viewPos),n2)));
			reflectedColor = mix(reflectedSkyColor * 0.0, reflectedColor, clamp(reflectedColorFalloff, 0.0, 1.0) );
		
		}
		
	}
#endif
*/