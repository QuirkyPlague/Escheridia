#ifndef GODRAYS_GLSL
#define GODRAYS_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"
#include "/lib/util.glsl"
#include "/lib/atmosphere/skyColor.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/blockID.glsl" 
  
 
vec3 sampleGodrays(vec3 godraySample, vec2 texcoord, vec3 feetPlayerPos, float depth)
{
	vec4 waterMask=texture(colortex4,texcoord);
  int blockID=int(waterMask)+100;
  
  bool isWater=blockID==WATER_ID;
	//godray parameters
    const float exposure = 0.35;
    float decay = 1.0;
    const float density = 1.0;
     float weight =  0.12; 
    
	//blank variables 
     godraySample = vec3(0.0);
    //alternate texcoord assignment
    vec2 altCoord = texcoord;
    //calculation of the sun position
    vec3 sunScreenPos = viewSpaceToScreenSpace(shadowLightPosition);
    sunScreenPos.xy = clamp(sunScreenPos.xy, vec2(-1.5), vec2(1.5));
	float VoL = dot(normalize(feetPlayerPos), sunScreenPos);
	vec2 deltaTexCoord = (texcoord - (sunScreenPos.xy)); 

    deltaTexCoord *= 1.0/ GODRAYS_SAMPLES * density;
	float illuminationDecay = 1.0;
	altCoord -= deltaTexCoord * IGN(gl_FragCoord.xy, frameCounter);

	
	float dist0 = length(screenToView(texcoord, depth));
	vec3 godrayColor;
  	float dist = dist0;
	 vec3 absorption = vec3(0.4, 0.5137, 0.9647);
	vec3 inscatteringAmount = calcSkyColor(godrayColor) * 0.6;
	vec3 absorptionFactor = exp(-absorption * 1.0 * (dist * 0.34));
    godrayColor *= absorptionFactor;
    godrayColor +=  inscatteringAmount / absorption * (1.0 - absorptionFactor);


    for(int i = 0; i < GODRAYS_SAMPLES; i++)
	{
	    vec3 samples = texture(depthtex0, altCoord).r == 1.0 ? godrayColor : vec3(0.0);
			if(inWater)
			{
				samples = texture(depthtex1, altCoord).r == 1.0 ? vec3(0.0118, 0.0235, 0.0588) : vec3(0.0);
				weight = 1.0;
			}
			
			samples *= illuminationDecay * weight;
			
			godraySample += samples;
			illuminationDecay *= decay;
			altCoord -= deltaTexCoord;
			if(clamp(altCoord, 0.0, 1.0) != altCoord){
					break;
                }
    }
	godraySample /= GODRAYS_SAMPLES * HG(0.6, -VoL);
	godraySample *= exposure;
	return godraySample;
}


#endif 