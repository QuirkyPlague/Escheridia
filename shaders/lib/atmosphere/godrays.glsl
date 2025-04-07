#ifndef GODRAYS_GLSL
#define GODRAYS_GLSL

#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"
#include "/lib/atmosphere/atmosphereColors.glsl"
#include "/lib/util.glsl"
#include "/lib/spaceConversions.glsl"

vec3 sampleGodrays(vec3 godraySample, vec2 texcoord)
{
    //godray parameters
    float exposure = GODRAYS_EXPOSURE;
    float decay = 1.0;
    float density = 1.0;
    float weight = 0.3 * SUN_ILLUMINANCE;
    float wetWeight = 0.65 - weight;
    
    //water masking/night checks
    vec4 waterMask = texture(colortex8, texcoord);
    int blockID = int(waterMask) + 100;
    bool isWater = blockID == WATER_ID;
    bool inWater = isEyeInWater == 1.0;
    bool isNight = worldTime >= 13000 && worldTime < 24000;
    
    //space conversions
    float depth = getDepth(texcoord);
    vec3 ndcPos = getNDC(texcoord, depth);
    vec3 viewPos = getViewPos(ndcPos);
    vec3 feetPlayerPos = getFeetPlayerPos(viewPos);
    vec3 worldPos = getWorldPos(feetPlayerPos);

    //blank variables 
    godraySample = vec3(0.0);
    vec3 godrayColor;
    vec3 waterTint;

    //alternate texcoord assignment
    vec2 altCoord = texcoord;

    //calculation of the sun position
    vec3 lightVector = viewSpaceToScreenSpace(shadowLightPosition);
    vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
    worldLightVector.xy = clamp(worldLightVector.xy, vec2(-0.5), vec2(1.0));
	vec2 deltaTexCoord = (texcoord - (lightVector.xy)); 
    float VoL = dot(normalize(feetPlayerPos), worldLightVector);

    deltaTexCoord *= rcp(GODRAYS_SAMPLES) * density;
	float illuminationDecay = 1.0;

	altCoord -= deltaTexCoord * IGN(gl_FragCoord.xy, frameCounter);
    for(int i = 0; i < GODRAYS_SAMPLES; i++)
	{
	    vec3 samples = texture(depthtex0, altCoord).r == 1.0 ? vec3(1.0) * getDayColor(godrayColor) : vec3(0.0);
        if (worldTime >= 0 && worldTime <  1000) 
			{
				float time = smoothstep(500, 1000, float(worldTime));
				samples = texture(depthtex0, altCoord).r == 1.0 ? mix(getDawnColor(godrayColor), getDayColor(godrayColor), time) : vec3(0.0);
			}
            else if (worldTime >= 12350 && worldTime <  23500) 
			{
				float time = smoothstep(12350, 13000, float(worldTime));
				samples = texture(depthtex0, altCoord).r == 1.0 ? vec3(1.0, 1.0, 1.0) * mix(getDawnColor(godrayColor), getNightColor(godrayColor), time) : vec3(0.0);
				weight = 0.08 * MOON_ILLUMINANCE;
				decay = 1.0;
				
			}
			else if (worldTime >= 1000 && worldTime <  12350) 
			{
				float time = smoothstep(10000, 12350, float(worldTime));
				samples = texture(depthtex0, altCoord).r == 1.0 ?  mix(getDayColor(godrayColor), getDawnColor(godrayColor), time) : vec3(0.0);
			}

			
			vec3 currentGodrayColor = samples;
			if(isWater)
				{
					samples = texture(depthtex1, altCoord).r == 1.0 ? mix(vec3(0.0, 0.4, 1.0), vec3(0.2902, 0.4431, 1.0), getWaterTint(waterTint)) : vec3(0.0);
				 	exposure = GODRAYS_EXPOSURE;
				} 
			if(inWater)
			{
					
					samples = texture(depthtex1, altCoord).r == 1.0 ? mix(vec3(0.2902, 0.4431, 1.0),vec3(0.2902, 0.4431, 1.0) , getWaterTint(waterTint)) : vec3(0.0);
				 	exposure = GODRAYS_EXPOSURE * 0.6;
			}

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
    }
    godraySample /= GODRAYS_SAMPLES * HG(0.785, -VoL);
	godraySample *= exposure;

    return godraySample;

}


#endif 