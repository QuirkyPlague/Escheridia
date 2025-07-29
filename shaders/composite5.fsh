#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/blockID.glsl"
#include "/lib/SSR.glsl" 
#include "/lib/uniforms.glsl"
#include "/lib/water/waves.glsl"
#include "/lib/atmosphere/skyColor.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
in vec2 texcoord;



/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() 
{
	color=texture(colortex0,texcoord);
	
	float depth = texture(depthtex0, texcoord).r;
	

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
	const int blockID3=int(sssMask)+103;

	//bools
	const bool isWater=blockID==WATER_ID;
	const bool isMetal = SpecMap.g >= 230.0/255.0;

	//space conversions
	vec3 screenPos = vec3(texcoord.xy, depth);
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 viewDir = normalize(viewPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	#if PIXELATED_LIGHTING ==1
	feetPlayerPos =floor((feetPlayerPos + cameraPosition) * 16) / 16 - cameraPosition;
    viewPos = (gbufferModelView * vec4(feetPlayerPos, 1.0)).xyz;
	#endif
	float farPlane = far/ 0.8;
	float normalFalloff = length(viewPos) / farPlane;
	float normalIntensityRolloff = exp(3.0  * (0.04 - normalFalloff));
	//normal assignments
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
	normal=mat3(gbufferModelView)*normal;
	

	#ifdef WAVES
	//waves
	float waveFalloff = length(feetPlayerPos) / farPlane;
	float waveIntensityRolloff = exp(15.0 * WAVE_INTENSITY * (0.08 - waveFalloff));
	float waveIntensity = 0.16 * WAVE_INTENSITY;
	waveIntensity *= waveIntensityRolloff;
	float waveSoftness = 0.3 * WAVE_SOFTNESS;
	if(isWater)
	{
		normal= waveNormal(feetPlayerPos.xz + cameraPosition.xz, waveSoftness, waveIntensity);
		normal = mat3(gbufferModelView) * normal;
	}
	#else
	if(isWater)
	{
		normal = normal;
	}
	#endif
	
	
	vec3 sunlightColor = vec3(0.0);
	const vec3 sunColor = currentSunColor(sunlightColor);

	vec3  f0 = vec3(0.0);
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
	{roughness = 0;}

	bool canReflect = roughness < 0.3;

	
	const vec3 reflectedDir = reflect(viewDir, normal);
    vec3 reflectedPos = vec3(0.0);
    vec3 reflectedColor = vec3(0.0);
	
	//SSR Calculations
	bool reflectionHit = false;
	float jitter = IGN(gl_FragCoord.xy, frameCounter * SSR_STEPS);
	const vec3 F=fresnelSchlick(max(dot(normal,-viewDir),0.),f0);
	#ifdef DO_SSR
	
	reflectionHit =  raytrace(viewPos, reflectedDir,SSR_STEPS, jitter,  reflectedPos);
	
	if(!isMetal && !isWater && !isColdBiome)
	{
		float originalRough =  pow(1.0 - SpecMap.r, 2.0);
		float wetRoughness = roughness * 0.02;
		roughness = mix(roughness, wetRoughness,  clamp( wetness, 0,1));
	
	}
	
	vec3 normalReflectedPos = reflectedPos;
	vec3 reflectedViewPos = screenSpaceToViewSpace(reflectedPos);
	float reflectedDist = distance(viewPos, reflectedViewPos);
	
	float lod = 0;
	if(roughness <= 0.0 || isWater) lod = 0.0;

	#ifdef ROUGH_REFLECTION
	const float sampleRadius = roughness * 0.12 * distance(reflectedViewPos, viewPos) ;
	
	for(int i = 0; i < ROUGH_SAMPLES; i++)
   	{
		jitter = IGN(gl_FragCoord.xy, frameCounter * ROUGH_SAMPLES);
		vec2 offset = vogelDisc(i, ROUGH_SAMPLES , jitter) * sampleRadius;
		vec3 offsetReflectedPos = reflectedPos + vec3(offset, 0.0); // add offset
		offsetReflectedPos.z = reflectedPos.z;
		reflectedPos = offsetReflectedPos;
			
	}
	#else
	lod = 0.0;
	#endif
	#endif
	
	#ifdef DO_SSR
	if(reflectionHit)
	{
		if(canReflect)
		{
				reflectedColor = texture2DLod(colortex0, reflectedPos.xy, lod).rgb;
				vec3 mieFog = atmosphericMieFog(reflectedColor, reflectedViewPos, texcoord, depth, lightmap, worldLightVector, sunColor);
				vec3 atmosphereFog = atmosphericFog(reflectedColor, reflectedViewPos, texcoord, depth, lightmap);
				vec3 fullFog = mix(atmosphereFog, mieFog, 0.3);
				reflectedColor = fullFog;
		}		
		if(reflectedPos.z == 1.0)
		{
			reflectedColor = vec3(0.0);
		}
	}
		if(!reflectionHit && canReflect)
			{
				vec3 skyMieReflection = calcMieSky(reflect(normalize(viewPos), normal), worldLightVector, sunColor, viewPos, texcoord) * 7 ;
					vec3 skyReflection = calcSkyColor(reflect(normalize(viewPos), normal)) * 5;
					vec3 sunReflection = skyboxSun(lightVector,reflect(normalize(viewPos), normal), sunColor) * 3;
					skyReflection = mix(sunReflection, skyReflection, 0.5);
					vec3 fullSkyReflection = mix(skyReflection, skyMieReflection, 0.5);
					reflectedColor = fullSkyReflection;
				float smoothLightmap = smoothstep(0.882, 1.0, lightmap.g);
				reflectedColor = mix(color.rgb, reflectedColor, smoothLightmap);
			}
	
	if(roughness < 0.1 + wetness && !isMetal && SpecMap.r <= 155.0/255.0 && !isWater && !isColdBiome)
	{
		
				reflectedColor = texture2DLod(colortex0, reflectedPos.xy, lod).rgb;
			
		 	if(!reflectionHit)
			{
				vec3 skyMieReflection = calcMieSky(reflect(normalize(viewPos), normal), worldLightVector, sunColor, viewPos, texcoord) * 7 ;
					vec3 skyReflection = calcSkyColor(reflect(normalize(viewPos), normal)) * 5;
					vec3 sunReflection = skyboxSun(lightVector,reflect(normalize(viewPos), normal), sunColor) * 3;
					skyReflection = mix(sunReflection, skyReflection, 0.5);
					vec3 fullSkyReflection = mix(skyReflection, skyMieReflection, 0.5);
					reflectedColor = fullSkyReflection;
			}
			float smoothLightmap = smoothstep(0.882, 1.0, lightmap.g);
			reflectedColor = mix(color.rgb, reflectedColor, smoothLightmap);
	}
	#else
	if(canReflect || isMetal || isWater)
	{
		if(!inWater)
		{
			vec3 skyMieReflection = calcMieSky(normalize(reflectedViewPos), worldLightVector, sunColor, viewPos, texcoord);
			vec3 skyReflection = calcSkyColor(reflect(normalize(viewPos), normal));
			vec3 sunReflection = skyboxSun(lightVector,reflect(normalize(viewPos), normal), sunColor) * 3;
			skyReflection = mix(sunReflection, skyReflection, 0.5);
			vec3 fullSkyReflection = mix(skyReflection, skyMieReflection, 0.1);
			reflectedColor = fullSkyReflection;
			reflectedColor *= smoothstep(0.815, 1.0, lightmap.g);
		}	
	}		
	#endif
	reflectedColor *= F;
	
	#ifdef DO_SSR
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
	#else
	color.rgb += reflectedColor;
	#endif
}