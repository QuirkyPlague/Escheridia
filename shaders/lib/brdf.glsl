#ifndef BRDF_GLSL
#define BRDF_GLSL

// [Gotanda 2012, "Beyond a Simple Physically Based Blinn-Phong Model in Real-Time"]
float OrenNayar(float roughness, float NdotL, float NdotV, float VdotH) {
  float m = roughness * roughness;
  float m2 = m * m;
  float VoL = 2.0 * VdotH - 1.0;
  float C1 = 1.0 - 0.5 * m2 / (m2 + 0.33);
  float Cosri = VoL - NdotV * NdotL;
  float C2 =
    0.45 *
    m2 /
    (m2 + 0.09) *
    Cosri *
    (Cosri >= 0.0
      ? clamp(NdotL / (NdotV + 1e-10), 0, 1)
      : NdotL);

  return NdotL * C1 + C2;
}

vec3 brdf(
  vec3 albedo,
  vec3 F0,
  vec3 L,
  vec3 currentSunlight,
  vec3 N,
  vec3 H,
  vec3 V,
  float roughness,
  vec4 SpecMap,
  vec3 indirect,
  vec3 shadow
) {
  vec3 Lo = vec3(0.0);

  // calculate per-light radiance
  float dist = length(L);
  float attenuation = 1.0 * (dist * dist);
  vec3 radiance = currentSunlight * shadow * attenuation;

  vec3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);

  // cook-torrance brdf
  float NDF = DistributionGGX(N, H, roughness);
  float G = GeometrySmith(N, V, L, roughness);

  vec3 numerator = NDF * G * F;
  float NdotL = clamp(dot(N, L), 0.0, 1.0);

  float denominator = 4.0 * NdotL + 0.0001;
  vec3 spec = numerator / denominator;
  if (NdotL < 0) return spec * 0;
  vec3 kS = F;
  vec3 kD = vec3(1.0) - kS;

  float NdotV = clamp(dot(N, V), 0.0, 1.0);
  float VdotH = clamp(dot(V, H), 0.0, 1.0);
  float orenDiffuse = OrenNayar(roughness, NdotL, NdotV, VdotH);
  orenDiffuse /= radians(180.0);
  #ifdef DO_SSR
  if (SpecMap.g >= 230.0 / 255.0) {
    kD *= 0.0;
  }
  #else
  kD *= 1.0;
  #endif
  // add to outgoing radiance Lo

  Lo = (kD * albedo + spec * 3) * radiance * orenDiffuse;

  indirect *= albedo / PI;

  return Lo + indirect;
}

#endif
