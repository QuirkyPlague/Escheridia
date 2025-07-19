#ifndef VOLUMETRICS_GLSL
#define VOLUMETRICS_GLSL

#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"
#include "/lib/util.glsl"
#include "/lib/atmosphere/skyColor.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/blockID.glsl" 
#include "/lib/lighting/lighting.glsl"
#include "/lib/SSR.glsl"
#include "/lib/shadows/drawShadows.glsl"

vec3 volumetricFog(vec3 feetPlayerPos, vec3 shadowScreenPos, float jitter, vec2 texcoord, float depth, vec3 lightPos)
{
    vec3 startPos = vec3(0.0, 0.0, 0.0);
    vec3 endPos = feetPlayerPos;
    int stepCount = GODRAYS_SAMPLES;
    bool intersected = false;
    float dist = length(screenToView(texcoord, depth));
    vec3 stepSize = (endPos - startPos) / stepCount;
    vec3 loopPos =  startPos + jitter * stepSize;
    vec3 shadowSum = vec3(0.0);
    
 
    for(int i = 0; i < GODRAYS_SAMPLES; i++) 
    {
   
  
   loopPos += stepSize;
   if (length(loopPos - startPos) < dist)
     break;
}
    shadowSum /= stepCount;
    vec3 absorption = vec3(5.0);
	vec3 vLColor;
    vec3 sunColor = currentSunColor(vLColor);
    float VoL = dot(normalize(feetPlayerPos), lightPos);
	vec3 inscatteringAmount = sunColor;
   vec3 absorptionFactor = exp(-absorption  * (dist * 0.8) * shadowSum);
    vLColor *= absorptionFactor;
    vLColor +=  inscatteringAmount / absorption * (1.0 - clamp(absorptionFactor, 0, 1));
    vLColor *= HG(0.56, VoL);
    return vLColor;
}

#endif