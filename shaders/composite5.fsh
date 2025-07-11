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
const bool colortex0MipmapEnabled = true;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() 
{
	
	color=textureLod(colortex0,texcoord, 0);
	
	float depth = texture(depthtex0, texcoord).r;
	if (depth == 1.0) return;

	//buffer assignments
	const vec4 SpecMap = texture(colortex5, texcoord);
	const vec3 albedo = texture(colortex0, texcoord).rgb;
	const vec3 encodedNormal = texture(colortex2,texcoord).rgb;
	const vec2 lightmap = texture(colortex1, texcoord).rg;
	const vec4 sssMask = texture(colortex11, texcoord);
	const vec4 waterMask=texture(colortex4,texcoord);
	const vec4 translucentMask=texture(colortex7,texcoord);
	
	//block IDs
	const int blockID=int(waterMask)+100;
	const int blockID2=int(translucentMask)+102;
	const int blockID3=int(sssMask)+103;

	//bools
	const bool canScatter = blockID3 == SSS_ID;
	const bool isTranslucent=blockID2==TRANSLUCENT_ID;
	const bool isWater=blockID==WATER_ID;
	const bool isMetal = SpecMap.g >= 230.0/255.0;

	//normal assignments
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
	normal=mat3(gbufferModelView)*normal;
	vec3 worldNormal = decodeNormal(encodedNormal.xy);
    vec3 normals = mat3(gbufferModelView) * worldNormal;
	if(isWater)
	{normal=normals;}
	//space conversions
	vec3 screenPos = vec3(texcoord.xy, depth);
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 viewDir = normalize(viewPos);
	
	const vec3 lightVector = normalize(shadowLightPosition);
	const vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
	vec3 sunlightColor;
	const vec3 sunColor = currentSunColor(sunlightColor);

	vec3  f0;
	if(isMetal)
  	{f0 = albedo;}
	else if(isWater)
	{f0 = vec3(0.02);}
	else
	{f0 = vec3(SpecMap.g);}
	if(inWater && isWater)
	{
		f0 = vec3(1.0);
	}
	float roughness;
 	roughness = pow(1.0 - SpecMap.r, 2.0);
	if(isWater)
	{roughness = 0.0;}

	vec3 F=fresnelSchlick(max(dot(normal,-viewDir),0.),f0);

	const vec3 reflectedDir = reflect(viewDir, normal);
    vec3 reflectedPos = vec3(0.0);
    vec3 reflectedColor = vec3(0.0);
	
	//SSR Calculations
	bool reflectionHit = false;
	float jitter = IGN(gl_FragCoord.xy, frameCounter * SSR_STEPS);
	#ifdef DO_SSR
	reflectionHit = true;
	reflectionHit && raytrace(viewPos, reflectedDir,SSR_STEPS, jitter,  reflectedPos);
	
	if(isRaining && !isMetal)
	{
		float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
		float currentRoughness = roughness;
		float wetRoughness = 0.05;
		roughness = mix(currentRoughness, wetRoughness, dryToWet);
		roughness += smoothstep(1.0, 0.74, lightmap.g);
	}
	vec3 normalReflectedPos = reflectedPos;
	vec3 reflectedViewPos = screenSpaceToViewSpace(reflectedPos);
	float reflectedDist = distance(viewPos, reflectedViewPos);
	float lod = min(4.5 * (1.0 - pow(roughness, 3.0)), reflectedDist *0.15);
	 reflectedPos.xy = clamp(reflectedPos.xy, vec2(-1.5), vec2(1.5));
	if(roughness <= 0.0) lod = 0.0;
	
	#ifdef ROUGH_REFLECTION
	
	const float sampleRadius = (roughness) *0.078 * distance(reflectedViewPos, viewPos);
	
	for(int i = 0; i < ROUGH_SAMPLES; i++)
   	{
      	vec2 offset = vogelDisc(i, ROUGH_SAMPLES , jitter) * sampleRadius;
		vec3 offsetReflectedPos = reflectedPos + vec3(offset, 0.0); // add offset
		offsetReflectedPos.z -= reflectedPos.z;
		reflectedPos = offsetReflectedPos;
		
	}
	#else
	lod = 0.0;
	#endif
	#endif

	#ifdef DO_SSR
	

	if(reflectionHit)
	{
		
			if(normalReflectedPos.z < 0.99992)
			{
				reflectedColor = texture2DLod(colortex0, reflectedPos.xy, lod).rgb;
			}
			else
			{
					vec3 skyMieReflection = calcMieSky(reflect(normalize(viewPos), normal), worldLightVector, sunColor, viewPos, texcoord);
      				vec3 skyReflection = calcSkyColor(reflect(normalize(viewPos), normal));
					vec3 fullSkyReflection = mix(skyReflection, skyMieReflection, 0.5);
					reflectedColor = fullSkyReflection;
					reflectedColor *= smoothstep(0.815, 1.0, lightmap.g);
					reflectedColor *= smoothstep(1.0, -0.5, lod);
			}
				if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && !inWater)
				{
					vec3 skyMieReflection = calcMieSky(reflect(normalize(viewPos), normal), worldLightVector, sunColor, viewPos, texcoord);
					vec3 skyReflection = calcSkyColor(reflect(normalize(viewPos), normal));
					vec3 fullSkyReflection = mix(skyReflection, skyMieReflection, 0.5);
					reflectedColor = fullSkyReflection;
					reflectedColor *= smoothstep(0.815, 1.0, lightmap.g);
					reflectedColor *= smoothstep(1.0, -0.90, lod);
				}
				if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && inWater)
				{
					reflectedColor = color.rgb;
					
				}
	
			reflectedColor *= smoothstep(0.0, 1.0, lod);
	}
	
	
	
	
	if(roughness <= 0.63 && isRaining && !isMetal && SpecMap.r <= 155.0/255.0 && !isWater)
	{
		if(reflectedPos.z < 1.0)
			{
				reflectedColor = texture2DLod(colortex0, reflectedPos.xy, lod).rgb;
			}
			else
			{
				vec3 skyMieReflection = calcMieSky(reflect(normalize(viewPos), normal), worldLightVector, sunColor, viewPos, texcoord);
      				vec3 skyReflection = calcSkyColor(reflect(normalize(viewPos), normal));
					vec3 fullSkyReflection = mix(skyReflection, skyMieReflection, 0.5);
					reflectedColor = fullSkyReflection;
					reflectedColor = mix(reflectedColor, reflectedColor, lod);
			}
		 	if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy)
			{
				vec3 skyMieReflection = calcMieSky(reflect(normalize(viewPos), normal), worldLightVector, sunColor, viewPos, texcoord);
      				vec3 skyReflection = calcSkyColor(reflect(normalize(viewPos), normal));
					vec3 fullSkyReflection = mix(skyReflection, skyMieReflection, 0.5);
					reflectedColor = fullSkyReflection;
					reflectedColor = mix(reflectedColor, reflectedColor, lod);
			}
			reflectedColor *= smoothstep(0.9, 1.0, lightmap.g);
	}
	#else
	if(isWater || SpecMap.r > 130.0/255.0 || isMetal)
	{
		vec3 skyMieReflection = calcMieSky(reflect(normalize(viewPos), normal), worldLightVector, sunColor, viewPos, texcoord) * 1.7;
      	vec3 skyReflection = calcSkyColor(reflect(normalize(viewPos), normal));
		vec3 fullSkyReflection = mix(skyReflection, skyMieReflection, 0.5);
		reflectedColor = fullSkyReflection;
		reflectedColor *= smoothstep(0.9, 1.0, lightmap.g);
	}
			
	#endif
	

	reflectedColor *= F;

	if(clamp(reflectedPos.xy, 0, 1) == reflectedPos.xy && isMetal)
	{color.rgb = reflectedColor;}
	else if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && isMetal)
	{color.rgb += reflectedColor;	}
	else if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && isMetal && lightmap.g > 0.74)
	{color.rgb = reflectedColor;}
	
	
	if(!isMetal)
	{
		color.rgb += reflectedColor;
	}

	
	
		
	

}