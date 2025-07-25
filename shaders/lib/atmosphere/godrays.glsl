#ifndef GODRAYS_GLSL
#define GODRAYS_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"
#include "/lib/util.glsl"
#include "/lib/atmosphere/skyColor.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/blockID.glsl" 
#include "/lib/lighting/lighting.glsl"

vec3 godrayAbsorp(vec3 color)
{
	color.r = GABSORB_R;
	color.g = GABSORB_G;
	color.b = GABSORB_B;
	return color;
}

vec3 sampleGodrays(vec3 godraySample, vec2 texcoord, vec3 feetPlayerPos, float depth)
{
	vec4 waterMask=texture(colortex4,texcoord);
  	int blockID=int(waterMask)+100;
  	bool isWater=blockID==WATER_ID;

	//godray parameters
    const float exposure = 0.3;
    const float decay = 1.0;
    const float density = 1.0;
    float weight =  0.12 * (GODRAY_DENSITY); 
    
	//blank variables 
     godraySample = vec3(0.0);

    //alternate texcoord assignment
    vec2 altCoord = texcoord;
    //calculation of the sun position
    vec3 sunScreenPos = viewSpaceToScreenSpace(shadowLightPosition);
    sunScreenPos.xy = clamp(sunScreenPos.xy, vec2(-0.5), vec2(1.5));

	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
	float VoL = dot(normalize(feetPlayerPos), worldLightVector);

	vec2 deltaTexCoord = (texcoord - (sunScreenPos.xy)); 
	
    deltaTexCoord *= 1.0 / GODRAYS_SAMPLES * density;
	float illuminationDecay = 1.0;
	altCoord -= deltaTexCoord * IGN(gl_FragCoord.xy, frameCounter);

	
	vec3 godrayColor;
	bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;

	vec3 absorption = vec3(0.0);
	absorption = godrayAbsorp(absorption) * 0.5;
	vec3 sunColor = currentSunColor(godrayColor);
	vec3 inscatteringAmount = sunColor;
	
	inscatteringAmount = mix(sunColor, sunColor , GODRAY_DENSITY + wetness);
	absorption = mix(absorption, vec3(0.7373, 0.7373, 0.7373), wetness  * 1.5);
	vec3 absorptionFactor = exp(-absorption  * (GODRAY_DENSITY));
    godrayColor *= absorptionFactor;
    godrayColor +=  inscatteringAmount / absorption * (1.0 - clamp(absorptionFactor, 0, 1));

	if(inWater)
	{
		weight += 0.33;
		absorption = waterColor(godrayColor);
		inscatteringAmount = waterScatter(inscatteringAmount);
		absorptionFactor = exp(-absorption  * (UNDERWATER_FOG_DENSITY + GODRAY_DENSITY));
    	godrayColor *= absorptionFactor;
    	godrayColor +=  inscatteringAmount / absorption * (1.0 - absorptionFactor);
	}
	
    for(int i = 0; i < GODRAYS_SAMPLES; i++)
	{
		vec3 samples = texture(depthtex0, altCoord).r == 1.0 ? godrayColor : vec3(0.0);
		if(inWater)
		{
			samples = texture(depthtex1, altCoord).r == 1.0 ? godrayColor : vec3(0.0);
		}
		samples *= illuminationDecay * weight;
		godraySample += samples;
		illuminationDecay *= decay;
		altCoord -= deltaTexCoord;
		if(clamp(altCoord, 0,1)!= altCoord)
		{
			break;
		}
    }

	godraySample /= GODRAYS_SAMPLES;
	if(inWater)
	{
		godraySample *= HG(0.32, VoL);
	}
	else
	{
		godraySample *= HG(0.78, VoL);
	}

	godraySample *= exposure;
	return godraySample;
}


#endif 