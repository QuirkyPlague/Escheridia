#ifndef FOG
#define FOG
#include "/lib/atmosphere/sky.glsl"

vec3 borderFog(vec3 color, vec3 dir, float depth) {
  vec3 fogColor = skyScattering(normalize(dir));
  float dist = length(dir) / far;
  float fogFactor = exp(-24.0 * (1.0 - dist));
  float rainFogFactor = exp(-7.37 * (1.0 - dist));
  fogFactor = mix(fogFactor, rainFogFactor, wetness);
  return mix(color, fogColor, clamp(fogFactor, 0.0, 1.0));
}

vec3 atmosphericFog(vec3 color, vec3 viewPos, float depth, vec2 lightmap) {
  vec3 sunColor = vec3(0.0);
  sunColor = currentSunColor(sunColor);
  float farPlane = far * 1.3;
  float dist0 = length(viewPos) / far;

  vec3 absorption = vec3(0.1176, 0.1176, 0.1176);

  vec3 inscatteringAmount = skyScattering(normalize(viewPos));
  inscatteringAmount = pow(inscatteringAmount, vec3(2.2));
  inscatteringAmount = mix(
    inscatteringAmount,
    vec3(0.8784, 0.8784, 0.8784),
    PaleGardenSmooth
  );
  inscatteringAmount *= eyeBrightnessSmooth.y;
  inscatteringAmount *= 0.0015;

  float dist = dist0;
  vec3 absorptionFactor = exp(-absorption * 1.0 * (dist * 1.0));

  float time = float(worldTime);
  float VdotL = dot(normalize(viewPos), worldLightVector);

  float smoothDepth = smoothstep(0.99899, 1.0, depth);

  float phase = CS(0.65, VdotL);

  vec3 phaseLighting = sunColor * 3 * phase * eyeBrightnessSmooth.y;
  phaseLighting *= 0.0025;

  color *= absorptionFactor;
  return color +=
    (inscatteringAmount + phaseLighting) /
    absorption *
    (1.0 - absorptionFactor);
}
#endif //FOG
