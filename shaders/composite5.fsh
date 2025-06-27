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

void main() {
color=texture(colortex0,texcoord);
	
	vec3 LightVector=normalize(shadowLightPosition);
	vec3 worldLightVector=mat3(gbufferModelViewInverse)*LightVector;
	
	//depth calculation
	float depth=texture(depthtex0,texcoord).r;
	float depth1=texture(depthtex1,texcoord).r;
	//buffer definitions
	vec4 SpecMap = texture(colortex5, texcoord);
	vec4 waterMask=texture(colortex4,texcoord);
	vec4 translucentMask=texture(colortex7,texcoord);
	int blockID=int(waterMask)+100;
	int blockID2=int(translucentMask)+102;
	bool isTranslucent=blockID2==TRANSLUCENT_ID;
	bool isWater=blockID==WATER_ID;
	vec3 geoNormal=texture(colortex6,texcoord).rgb;
	vec3 encodedNormal= texture(colortex2, texcoord).rgb;
	vec3 normal=normalize((encodedNormal-.5)*2.);// we normalize to make sure it is out of unit length
	vec3 n2 =mat3(gbufferModelView)*normal;
	vec3 geometryNormal=normalize((geoNormal-.5)*2.);// we normalize to make sure it is out of unit length
	
	vec3 worldNormal = decodeNormal(encodedNormal.xy);
    vec3 normals = mat3(gbufferModelView) * worldNormal;
	
	
	float sss = SpecMap.b;

	
	//Space Conversions
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 worldPos = cameraPosition + feetPlayerPos;
//lightmap
	vec2 lightmap=texture(colortex1,texcoord).rg;
	vec3 albedo = texture(colortex0, texcoord).rgb;
	lightmap = clamp(lightmap, 0, 1);
  	vec3 viewDir=normalize(viewPos);

	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;

	vec3 shadow = getSoftShadow(shadowClipPos, feetPlayerPos, geoNormal, texcoord, shadowScreenPos, sss);
	bool isMetal = SpecMap.g >= 230.0/255.0;
	bool isOpaque = !isWater;
	vec3 clouds = texture(colortex10, texcoord).rgb;
	
	
	vec3  f0;
	if(isMetal)
  	{
    	f0 = albedo;
  	}
	else if(isWater)
	{
		f0 = vec3(0.02);
	}
	else
	{
		f0 = vec3(SpecMap.g);
	}
	
	

	


	float roughness;
 	roughness = pow(1.0 - SpecMap.r, 2.0);
	if(isWater)
	{
		roughness = 0.05;
	}
		
	
		
	vec3 sunlight;
	vec3 currentSunlight = getCurrentSunlight(sunlight, normal, shadow, worldLightVector);
		
	vec3 reflectedDir = reflect(viewDir, n2);
    vec3 reflectedPos = vec3(0.0);
    vec3 reflectedColor = vec3(0.0);
if(isWater)
{
	reflectedDir = reflect(viewDir, normals);
}
	
	
	vec3 V= normalize(-viewDir);
	vec3 F=fresnelSchlick(max(dot(n2,-viewDir),0.),f0);
	
	//for specular highlights
	vec3 V2 = normalize(cameraPosition - worldPos);
    vec3 L = normalize(worldLightVector);
  	vec3 H = normalize(V2 + L);
	
	//SSR Calculations
	bool reflectionHit = true;
	float jitter = IGN(gl_FragCoord.xy, frameCounter);
	reflectionHit && raytrace(viewPos, reflectedDir,SSR_STEPS, jitter,  reflectedPos);
	bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;
	float skyDepth = 1.0;
	
	 if( isWater || SpecMap.r >= 155.0/255.0)
	{
	 if(reflectionHit)
	 {
		#if DO_SSR == 1
		
		if(reflectedPos.z < 1.0)
		{
			reflectedColor = texture(colortex0, reflectedPos.xy).rgb;	
		}
		else
		{
			vec3 skyReflection =calcSkyColor((reflect(normalize(reflectedPos),n2)));
			reflectedColor = skyReflection;
		}
			 if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && !inWater)
			{
				
				reflectedColor=calcSkyColor((reflect(normalize(reflectedPos),n2)));
				if(!inWater)
				{
					reflectedColor *= lightmap.g;
				}
				if(isMetal)
			{
				reflectedColor *= 0.5;
			}
				
			}
		#else
				
				vec3 skyReflection =calcSkyColor((reflect(normalize(reflectedPos),n2)));
				reflectedColor = skyReflection;
				if(!inWater)
				{
					reflectedColor *= lightmap.g;
				}
					if(isMetal)
			{
				reflectedColor *= 0.5;
			}
		#endif
	 }
	}
	if(isMetal && SpecMap.r < 155.0/255.0 )
	{
		reflectedColor=calcSkyColor((reflect(normalize(reflectedPos),n2)));
		reflectedColor *= lightmap.g;
		reflectedColor *= 0.2;
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
		reflectedColor *= F;

	vec3 specular = brdf(albedo, f0, L, currentSunlight, normal, H, V2, roughness, SpecMap) + reflectedColor;
	
	
	if(inWater)
	{
		currentSunlight *= WATER_SCATTERING;
		specular = brdf(albedo, f0, L, currentSunlight, normal, H, V2, roughness, SpecMap) + reflectedColor;
	}
	vec3 lighting =  specular ;
	
	if(clamp(reflectedPos.xy, 0, 1) == reflectedPos.xy && isMetal)
	{
		color.rgb = reflectedColor;
	}
	else if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && isMetal && lightmap.g < 0.55)
	{
		color.rgb += reflectedColor;
	}
	else if(clamp(reflectedPos.xy, 0, 1) != reflectedPos.xy && isMetal && lightmap.g > 0.74)
	{
		color.rgb = reflectedColor;
	}


	if(isWater)
	{
		color.rgb+= specular;
	}
		
	else{
		color.rgb += specular;
	}
	}