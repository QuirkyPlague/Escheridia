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
#include "/lib/water/waves.glsl"
#include "/lib/brdf.glsl"
#include "/lib/blockID.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blur.glsl"
in vec2 texcoord;



/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() 
{
	color=textureLod(colortex0,texcoord, 0);
	
	float depth = texture(depthtex0, texcoord).r;
	if(depth == 1) return;

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

	//normal assignments
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
	normal=mat3(gbufferModelView)*normal;
	float waveIntensity = 0.2 * WAVE_INTENSITY;
	float waveSoftness = 0.3 * WAVE_SOFTNESS;
	if(isWater)
	{
		normal= waveNormal(feetPlayerPos.xz + cameraPosition.xz, waveSoftness, waveIntensity);
		normal = mat3(gbufferModelView) * normal;
	}

	
	const vec3 lightVector = normalize(shadowLightPosition);
	const vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
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
	{roughness = 0.00;}


	const vec3 F=fresnelSchlick(max(dot(normal,-viewDir),0.),f0);
	const vec3 reflectedDir = reflect(viewDir, normal);
    vec3 reflectedPos = vec3(0.0);
    vec3 reflectedColor = vec3(0.0);
	
	//SSR Calculations
	bool reflectionHit = false;
	float jitter = IGN(gl_FragCoord.xy, frameCounter * SSR_STEPS);
	
	#ifdef DO_SSR
	reflectionHit = true;
	reflectionHit && raytrace(viewPos, reflectedDir,SSR_STEPS, jitter,  reflectedPos);
	
	if(!isMetal && !isWater)
	{
		float currentRoughness = roughness;
		float wetRoughness = 0.03;
		roughness = mix(currentRoughness, wetRoughness,  clamp( wetness, 0,1));
	}
	vec3 normalReflectedPos = reflectedPos;
	vec3 reflectedViewPos = screenSpaceToViewSpace(reflectedPos);
	float reflectedDist = distance(viewPos, reflectedViewPos);
	
	float lod = min(4.0 * (1.0 -pow(roughness, 4.0)), reflectedDist);
	if(roughness <= 0.0) lod = 0.0;

	#ifdef ROUGH_REFLECTION
	const float sampleRadius = roughness * 0.1 * distance(reflectedViewPos, viewPos) ;
	
	for(int i = 0; i < ROUGH_SAMPLES; i++)
   	{
      	vec2 offset = vogelDisc(i, ROUGH_SAMPLES , jitter) * sampleRadius;
		vec3 offsetReflectedPos = reflectedPos + vec3(offset, 0.0); // add offset
		reflectedPos = offsetReflectedPos;
	}
	#else
	lod = 0.0;
	#endif
	#endif
	bool canReflect = roughness < 0.3;
	#ifdef DO_SSR
	if(reflectionHit)
	{
		if(canReflect || isMetal || isWater)
		{
			if(normalReflectedPos.z < 0.99995)
			{
				reflectedColor = texture2DLod(colortex0, reflectedPos.xy, lod).rgb;
				
			}
			else
			{
				vec3 skyMieReflection = calcMieSky(reflect(normalize(viewPos), normal), worldLightVector, sunColor, viewPos, texcoord) * 13 ;
				vec3 skyReflection = calcSkyColor(reflect(normalize(viewPos), normal)) * 5;
				vec3 sunReflection = skyboxSun(lightVector,reflect(normalize(viewPos), normal), sunColor);
				skyReflection = mix(sunReflection, skyReflection, 0.5);
				vec3 fullSkyReflection = mix(skyReflection, skyMieReflection, 0.5);
				reflectedColor = fullSkyReflection;
				reflectedColor *= smoothstep(0.815, 1.0, lightmap.g);
			}

			if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && !inWater)
			{
				vec3 skyMieReflection = calcMieSky(reflect(normalize(viewPos), normal), worldLightVector, sunColor, viewPos, texcoord) * 13 ;
				vec3 skyReflection = calcSkyColor(reflect(normalize(viewPos), normal)) * 5 ;
				vec3 sunReflection = skyboxSun(lightVector,reflect(normalize(viewPos), normal), sunColor) ;
				skyReflection = mix(sunReflection, skyReflection, 0.5);
				vec3 fullSkyReflection = mix(skyReflection, skyMieReflection, 0.5);
				reflectedColor = fullSkyReflection;
				reflectedColor *= smoothstep(0.815, 1.0, lightmap.g);	
			}
			if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && inWater)
			{
				reflectedColor = color.rgb;	
			}
		}		
	}
	if(roughness < 0.1 + wetness && !isMetal && SpecMap.r <= 155.0/255.0 && !isWater)
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
	if(canReflect || isMetal || isWater)
	{
		if(!inWater)
		{
			vec3 skyMieReflection = calcMieSky(reflect(normalize(viewPos), normal), worldLightVector, sunColor, viewPos, texcoord);
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