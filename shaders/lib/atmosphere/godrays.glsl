#ifndef GODRAYS_GLSL
#define GODRAYS_GLSL

#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"
#include "/lib/atmosphere/atmosphereColors.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/util.glsl"
#include "/lib/spaceConversions.glsl"
#include "/lib/materials.glsl"

vec3 sampleGodrays(vec3 godraySample, vec2 texcoord)
{
    //godray parameters
    float exposure = GODRAYS_EXPOSURE;
    float decay = 1.0;
    float density = 1.0;
    float weight =0.3 * SUN_ILLUMINANCE;
    float wetWeight = 0.65 - weight;
    
    //water masking/night checks
    vec4 waterMask = texture(colortex8, texcoord);
    int blockID = int(waterMask) + 100;
    bool isWater = blockID == WATER_ID;
    bool inWater = isEyeInWater == 1.0;
    bool isNight = worldTime >= 13000 && worldTime < 24000;
    
    //space conversions
    float depth = getDepth1(texcoord);
    vec3 ndcPos = getNDC(texcoord, depth);
    vec3 viewPos = getViewPos(ndcPos);
    vec3 feetPlayerPos = getFeetPlayerPos(viewPos);
    vec3 worldPos = getWorldPos(feetPlayerPos);
	
	 vec3 godrayColor;
	vec3 albedo = getAlbedo(texcoord);
	if(depth == 1.0 && !inWater)
	{
		discard;
	}

    //blank variables 
    godraySample = vec3(0.0);

    vec3 waterTint;

    //alternate texcoord assignment
    vec2 altCoord = texcoord;

    //calculation of the sun position
    vec3 sunScreenPos = viewSpaceToScreenSpace(shadowLightPosition);
    vec3 worldLightVector = mat3(gbufferModelViewInverse) * sunScreenPos;
    sunScreenPos.xy = clamp(sunScreenPos.xy, vec2(-1.5), vec2(1.5));
	 worldLightVector.xy = clamp(worldLightVector.xy, vec2(-0.5), vec2(1.5));
	vec2 deltaTexCoord = (texcoord - (sunScreenPos.xy)); 
    float VoL = dot(normalize(feetPlayerPos), worldLightVector);

    deltaTexCoord *= rcp(GODRAYS_SAMPLES) * density;
	float illuminationDecay = 1.0;

	altCoord -= deltaTexCoord * IGN(gl_FragCoord.xy, frameCounter);
    for(int i = 0; i < GODRAYS_SAMPLES; i++)
	{
	    vec3 samples = texture(depthtex0, altCoord).r == 1.0 ? godrayRGB(godrayColor) *  calcSkyColor(godrayColor)  : vec3(0.0);
			if(isNight)
			{
				samples = texture(depthtex0, altCoord).r == 1.0 ?vec3(0.1098, 0.251, 0.5804) *  calcSkyColor(godrayColor) * 4.5: vec3(0.0);
			}
			vec3 currentGodrayColor = samples;
			if(isWater && !isNight)
				{
					
					samples = texture(depthtex1, altCoord).r == 1.0 ? mix(vec3(1.0), calcSkyColor(godrayColor), getWaterTint(waterTint)) : vec3(0.0);
				 	exposure = GODRAYS_EXPOSURE;
				} 
				if(isWater && isNight)
				{
					samples = texture(depthtex1, altCoord).r == 1.0 ? mix(vec3(0.0392, 0.0824, 0.1804), calcSkyColor(godrayColor), vec3(0.0353, 0.1059, 0.2039)) * 0.1 : vec3(0.0);
				 	exposure = GODRAYS_EXPOSURE;
				}
			#if DO_WATER_FOG == 1
			if(inWater)
			{
					
					samples = texture(depthtex1, altCoord).r == 1.0 ? mix(vec3(0.0, 0.2157, 1.0),vec3(0.1059, 0.298, 0.9882) , getWaterTint(waterTint)) : vec3(0.0);
				 	exposure = GODRAYS_EXPOSURE * 0.4;
					weight = 0.65 * WATER_FOG_DENSITY;
			}
				#endif
			if(rainStrength <= 1.0 && rainStrength > 0.0 && !isNight)
			{
				float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
				samples = texture(depthtex0, altCoord).r == 1.0 ? mix(currentGodrayColor, getRainColor(godrayColor), dryToWet) : vec3(0.0);
				 weight = mix(weight, wetWeight, dryToWet);
			}
			else if(rainStrength <= 1.0 && rainStrength > 0.0 && isNight)
			{
				float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
				samples = texture(depthtex0, altCoord).r == 1.0 ? mix(currentGodrayColor, getRainColor(godrayColor) / 4, dryToWet) : vec3(0.0);
				 weight = mix(weight, wetWeight, dryToWet);
			}
			
			samples *= illuminationDecay * weight ;
			godraySample += samples;
			illuminationDecay *= decay;
			altCoord -= deltaTexCoord;
			if(clamp(altCoord, 0.0, 1.0) != altCoord){
					break;
                }
    }
    godraySample /= GODRAYS_SAMPLES * HG(GODRAY_ASYMMETRY, -VoL);
	godraySample *= exposure;
	if(inWater)
	{
		#if DO_WATER_FOG == 1
		godraySample = godraySample;
		#else
		godraySample = vec3(0.0);
		#endif
	}
    return godraySample;

}


#endif 