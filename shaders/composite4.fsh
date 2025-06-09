#version 330 compatibility

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

in vec2 texcoord;




/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	
	//buffer definitions
	vec4 SpecMap = texture(colortex5, texcoord);
	vec4 waterMask=texture(colortex4,texcoord);
	vec4 translucentMask=texture(colortex7,texcoord);
	int blockID=int(waterMask)+100;
	bool isWater=blockID==WATER_ID;
	float depth = texture(depthtex0, texcoord).r;
	
	if(depth ==1) return;
	//lightmap/normals
	vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components
	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
	normal=mat3(gbufferModelView)*normal;
	vec3 albedo = texture(colortex0,texcoord).rgb;
	vec3 N =normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
	vec3 baseNormal = texture(colortex6, texcoord).rgb;
	vec3 geoNormal = normalize((baseNormal - 0.5) * 2.0); 

	//space conversions
	vec3 NDCPos=vec3(texcoord.xy,depth)*2.-1.;
 	vec3 viewPos=projectAndDivide(gbufferProjectionInverse,NDCPos);
  	vec3 viewDir=normalize(viewPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 worldPos = cameraPosition + feetPlayerPos;
	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;

	vec3 shadow = getSoftShadow(shadowClipPos, feetPlayerPos, geoNormal, texcoord, shadowScreenPos);
	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
	bool isMetal = SpecMap.g >= 230.0/255.0;
	bool isOpaque = !isWater;
	vec3  f0;
	if(!isMetal)
  	{
    	f0 = vec3(SpecMap.g);
  	}
	else if(isWater && !isOpaque && !isMetal)
	{
		f0 =vec3(0.02);
	}
	else
	{
		f0 = albedo;
	}

	float roughness;
 	roughness = pow(1.0 - SpecMap.r, 2.0);
	if(isWater && !isOpaque)
	{
		roughness = 0.05;
	}
		
	
		
	vec3 sunlight;
	vec3 currentSunlight = getCurrentSunlight(sunlight, N, shadow, worldLightVector);
		
	vec3 reflectedDir = reflect(viewDir, normal);
    vec3 reflectedPos = vec3(0.0);
    vec3 reflectedColor = vec3(0.0);

	//reflectedPos.xy = clamp(reflectedPos.xy, vec2(-1.5), vec2(1.5));
	
	vec3 V= normalize(-viewDir);
	vec3 F=fresnelSchlick(max(dot(normal,V),0.),f0);
	
	//for specular highlights
	vec3 V2 = normalize(cameraPosition - worldPos);
    vec3 L = normalize(worldLightVector);
  	vec3 H = normalize(V2 + L);
	
	//SSR Calculations
	bool reflectionHit = true;
	float jitter = IGN(gl_FragCoord.xy, frameCounter);
	reflectionHit && raytrace(viewPos, reflectedDir,SSR_STEPS, jitter,  reflectedPos);
	bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;

	
	 if(isWater || SpecMap.r >= 155.0/255.0)
	{
	 if(reflectionHit)
	 {
		#if DO_SSR == 1
		reflectedColor = texture(colortex0, reflectedPos.xy).rgb;
		
			 if(clamp(reflectedPos.xy, 0.0, 1.0) != reflectedPos.xy && !inWater)
			{
				
				reflectedColor=calcSkyColor((reflect(normalize(viewPos),normal)));
				if(isMetal)
				{
					reflectedColor *= 0.4;
				}
				reflectedColor *= lightmap.g;
				
			}
		#else
				reflectedColor=calcSkyColor((reflect(normalize(viewPos),normal)));
				reflectedColor = color.rgb + (lightmap.g * reflectedColor);
		
		#endif
	 }
	}
if(isRaining)
	{
		float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
		float currentRoughness = roughness;
		float wetRoughness = 0.15;
		roughness = mix(currentRoughness, wetRoughness, dryToWet);
	}
	if(roughness <= 0.35 && isRaining)
	{
		reflectedColor = texture(colortex0, reflectedPos.xy).rgb;
		if(lightmap.g <= 0.3)
		{
			reflectedColor *= 0;
		}
	}

		

	vec3 specular = max(brdf(albedo, f0, L, currentSunlight, N, H, V2, roughness, SpecMap), 0.0) + reflectedColor * F;
	
	
	if(inWater)
	{
		currentSunlight *= WATER_SCATTERING;
		specular = max(brdf(albedo, f0, L, currentSunlight, N, H, V2, roughness, SpecMap), 0.0)  + reflectedColor * F;
	}
	vec3 lighting =  specular ;
	if(isMetal)
	{
		color.rgb = specular;
	}
	
	
	color.rgb += lighting;
	
		
	
	}