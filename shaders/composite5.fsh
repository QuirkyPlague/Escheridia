#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/blockID.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/SSR.glsl" 
#include "/lib/uniforms.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/brdf.glsl"
#include "/lib/blockID.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() 
{
	color=texture(colortex0,texcoord);

	float depth = texture(depthtex0, texcoord).r;
	if (depth == 1.0) return;

	//buffer assignments
	vec4 SpecMap = texture(colortex5, texcoord);
	vec3 albedo = texture(colortex0, texcoord).rgb;
	vec3 encodedNormal = texture(colortex2,texcoord).rgb;
	vec2 lightmap = texture(colortex1, texcoord).rg;
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
	normal=mat3(gbufferModelView)*normal;
	vec3 worldNormal = decodeNormal(encodedNormal.xy);
    vec3 normals = mat3(gbufferModelView) * worldNormal;
	if(isWater)
	{normal=normals;}
	//space conversions
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 viewDir = normalize(viewPos);
	
	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
	vec3 sunlightColor;
	vec3 sunColor = currentSunColor(sunlightColor);

	vec3  f0;
	if(isMetal)
  	{f0 = albedo;}
	else if(isWater)
	{f0 = vec3(0.02);}
	else
	{f0 = vec3(SpecMap.g);}

	float roughness;
 	roughness = pow(1.0 - SpecMap.r, 2.0);
	
	if(isWater)
	{roughness = 0.05;}

	vec3 F=fresnelSchlick(max(dot(normal,-viewDir),0.),f0);

	vec3 reflectedDir = reflect(viewDir, normal);
    vec3 reflectedPos = vec3(0.0);
    vec3 reflectedColor = vec3(0.0);
	
	//SSR Calculations
	bool reflectionHit = true;
	float jitter = IGN(gl_FragCoord.xy, frameCounter);
	reflectionHit && raytrace(viewPos, reflectedDir,SSR_STEPS, jitter,  reflectedPos);
	reflectedPos.xy = clamp(reflectedPos.xy, vec2(-1.5), vec2(1.5));
	if(reflectionHit)
	{
		if(isWater || roughness < 55.0/255.0)
		{
			if(reflectedPos.z < 1.0)
			{
				reflectedColor = texture(colortex0, reflectedPos.xy).rgb;
			}
			else
			{
				if(!inWater)
				{
					vec3 skyMieReflection = calcMieSky(normalize(viewPos), worldLightVector, sunColor, viewPos, texcoord);
					vec3 skyReflection =calcSkyColor((reflect(normalize(viewPos),normal)));
					reflectedColor= mix(skyReflection, skyMieReflection, 0.6);
					reflectedColor *= lightmap.g;
				}
			
			}
		 	if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && !inWater)
			{
				vec3 skyMieReflection = calcMieSky(normalize(viewPos), worldLightVector, sunColor, viewPos, texcoord);
				vec3 skyReflection =calcSkyColor((reflect(normalize(viewPos),normal)));
				reflectedColor= mix(skyReflection, skyMieReflection, 0.6);
				reflectedColor *= lightmap.g;
			
			}
		}
	}
	if(isMetal && roughness > 55.0/255.0 )
	{
		vec3 skyMieReflection = calcMieSky(normalize(viewPos), worldLightVector, sunColor, viewPos, texcoord) * 1.7;
		vec3 skyReflection =calcSkyColor((reflect(normalize(viewPos),normal)));
		reflectedColor= mix(skyReflection, skyMieReflection, 0.6);
		reflectedColor *= lightmap.g;
		reflectedColor *= 0.6;
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
		if(reflectedPos.z < 1.0)
			{
				reflectedColor = texture(colortex0, reflectedPos.xy).rgb;
			}
			else
			{
				vec3 skyMieReflection = calcMieSky(normalize(viewPos), worldLightVector, sunColor, viewPos, texcoord) * 1.7;
				vec3 skyReflection =calcSkyColor((reflect(normalize(viewPos),normal)));
				reflectedColor= mix(skyReflection, skyMieReflection, 0.5);
				reflectedColor *= lightmap.g;
			}
		 	if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && !inWater)
			{
				vec3 skyMieReflection = calcMieSky(normalize(viewPos), worldLightVector, sunColor, viewPos, texcoord) * 1.7;
				vec3 skyReflection =calcSkyColor((reflect(normalize(viewPos),normal)));
				reflectedColor= mix(skyReflection, skyMieReflection, 0.5);
				reflectedColor *= lightmap.g;
			
			}
		if(lightmap.g < 0.9935)
		{ 
			float reflectedColorFalloff = exp(-5.512 * (1.214 - lightmap.g));
			vec3 skyMieReflection = calcMieSky(normalize(viewPos), worldLightVector, sunColor, viewPos, texcoord) * 1.7;
			vec3 skyReflection =calcSkyColor((reflect(normalize(viewPos),normal)));
			vec3 reflectedSkyColor = mix(skyReflection, skyMieReflection, 0.5);
			reflectedColor = mix(reflectedSkyColor * 0.0, reflectedColor, clamp(reflectedColorFalloff, 0.0, 1.0) );
		
		}
	}
	#endif

	reflectedColor *= F;
	if(clamp(reflectedPos.xy, 0, 1) == reflectedPos.xy && isMetal)
	{color.rgb = reflectedColor;}
	else if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && isMetal && lightmap.g < 0.55)
	{color.rgb += reflectedColor;	}
	else if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && isMetal && lightmap.g > 0.74)
	{color.rgb = reflectedColor;}

	
	if(!isMetal)
	{color.rgb += reflectedColor;}

	
	
		
	

}