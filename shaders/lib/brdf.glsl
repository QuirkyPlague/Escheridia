#ifndef BRDF
#define BRDF

#include "/lib/tonemapping.glsl"

vec3 brdf(
  vec3 albedo,
  vec3 F0,
  vec3 currentSunlight,
  vec3 N,
  vec3 H,
  vec3 V,
  float roughness,
  vec3 indirect,
  vec3 shadow,
  bool isMetal
) {
  vec3 Lo = vec3(0.0);
  vec3 L = worldLightVector;
  // calculate per-light radiance
  float dist = length(L);
  float attenuation = 1.0 / (dist * dist);
  currentSunlight += max(6.75 * pow(currentSunlight, vec3(0.75)), 0.0);

  vec3 radiance = currentSunlight * shadow * attenuation;

  vec3 F = fresnelSchlick(max(dot(H, V), 0.0001), F0);

  // cook-torrance brdf
  float NDF = DistributionGGX(N, H, roughness);
  float G = GeometrySmith(N, V, L, roughness);

  vec3 numerator = NDF * G * F;

  float NdotL = clamp(dot(N, L), 0.0, 1.0);
  float NdotV = clamp(dot(N, V), 0.0, 1.0);
  float VdotH = clamp(dot(V, H), 0.0, 1.0);

  float denominator = 4.0 * NdotV * NdotL + 0.0001;
  vec3 spec = numerator / denominator;
  
  spec = lottesTonemap(spec);

  vec3 kS = F;
  vec3 kD = vec3(1.0) - kS;

  if (NdotL < 1e-6) {
    spec = vec3(0.0);
  }

  #ifdef DO_SSR
  if (isMetal) {
    kD *= 0.45;

  }
  #else
  kD *= 1.0;
  #endif

  // add to outgoing radiance Lo

  Lo = (kD * albedo / PI + spec) * radiance * NdotL;

  indirect *= albedo / PI;

  return Lo + indirect;
}

#endif
