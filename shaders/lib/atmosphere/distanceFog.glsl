#ifndef DISTANCE_FOG_GLSL
#define DISTANCE_FOG_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/skyColor.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/phaseFunctions.glsl"

vec3 distanceFog(vec3 color, vec3 eyePos, vec2 texcoord, float depth) {
  vec3 sunColor = vec3(0.0);
  sunColor = currentSunColor(sunColor);
  vec3 distFog = vec3(0.0);

  distFog = newSky(eyePos) + wetness;
  float dist = length(eyePos) / far ;
  float fogFactor = exp(-9.0 * (1.0 - dist));
  float rainFogFactor = exp(-15.5 * (1.0 - dist));
  bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;
  if (isRaining) {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    fogFactor = mix(fogFactor, rainFogFactor, dryToWet);

    distFog = mix(distFog, distFog, dryToWet) * 0.23;
  }
  if (isRaining && isNight) {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    fogFactor = mix(fogFactor, rainFogFactor, dryToWet);

    distFog = mix(distFog, distFog, dryToWet) * 0.15;
  }

  color = mix(color, distFog, clamp(fogFactor, 0, 1));

  return color;
}


vec3 atmosphericFog(
  vec3 color,
  vec3 viewPos,
  vec2 texcoord,
  float depth,
  vec2 lightmap
) {
  vec3 sunColor = vec3(0.0);
  sunColor = currentSunColor(sunColor);
  float dist0 = length(viewPos) / 6;

  float farPlane = far / 4;
  float dist1 = length(viewPos) / farPlane;

  vec3 absorption = vec3(0.302, 0.302, 0.302);

  vec3 inscatteringAmount = vec3(0.2118, 0.3412, 0.9216);

  inscatteringAmount *= eyeBrightnessSmooth.y;
  inscatteringAmount *= 0.002;
  vec3 caveInscatter = vec3(0.0627, 0.0745, 0.1451);
  inscatteringAmount = mix(inscatteringAmount, caveInscatter * 4, moodSmooth);

  float dist = dist0;
  vec3 absorptionFactor = exp(-absorption * 1.0 * (dist * AIR_FOG_DENSITY));

  if (!isNight) {
    inscatteringAmount += wetness * 0.14;
  } else {
    inscatteringAmount += wetness * 0.06;
  }
  float VdotL = dot(normalize(viewPos), worldLightVector);
  float smoothDepth = smoothstep(0.9991,1.0 , depth);
  float phase = CS(0.65, VdotL);
  float backPhase = CS(-0.15, VdotL);
  
  vec3 phaseLighting = sunColor * 3 * phase * smoothDepth * eyeBrightnessSmooth.y;
  phaseLighting *= 0.0015;
    if (isNight) {
    phaseLighting *= 0.5;
    inscatteringAmount *= 0.01;
   
    }
 float rayleigh = Rayleigh(VdotL) * RAYLEIGH_COEFF;
  color *= absorptionFactor;
  return color += ((inscatteringAmount + phaseLighting)) / absorption * (1.0 - absorptionFactor);
}

#endif //DISTANCE_FOG_GLSL
