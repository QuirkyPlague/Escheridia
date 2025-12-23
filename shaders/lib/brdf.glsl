#ifndef BRDF
#define BRDF

#include "/lib/tonemapping.glsl"

float BurleyFrostbite(float roughness, float n_dot_l, float n_dot_v, float v_dot_h)
{
    float energyBias = 0.5 * roughness;
    float energyFactor = mix(1.0, 1.0 / 1.51, roughness);

    float FD90MinusOne = energyBias + 2.0 * v_dot_h * v_dot_h * roughness - 1.0f;
    float FDL = 1.0f + (FD90MinusOne * pow(1.0f - n_dot_l, 5.0f));
    float FDV = 1.0f + (FD90MinusOne * pow(1.0f - n_dot_v, 5.0f));

    return FDL * FDV * energyFactor;
}


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
  currentSunlight *= 9;

  vec3 radiance = currentSunlight * shadow * attenuation;

  
  float NdotL = clamp(dot(N, L), 0.0, 1.0);
  float NdotV = clamp(dot(N, V), 0.0, 1.0);
  float NdotH = clamp(dot(N, V), 0.0, 1.0);
  float VdotH = clamp(dot(V, H), 0.0, 1.0);
  vec3 F = fresnelSchlick(max(dot(H, V), 0.0001), F0);
  
  // cook-torrance brdf

  float NDF = DistributionGGX(N, H, roughness);
  float G = GeometrySmith(N, V, L, roughness);
  
  vec3 numerator = NDF * G * F;



  float denominator = 3.0 * NdotV * NdotL + 0.0001;
  vec3 spec = numerator / denominator;
 
 spec = min(spec, vec3(150.0));
 if(isMetal) spec = min(spec, vec3(0.6));
 
 
  float diff = BurleyFrostbite(roughness, NdotL,NdotV, VdotH);
  diff /= PI;
  vec3 kS = F;
  vec3 kD = vec3(1.0) - kS;

  if (NdotL < 1e-6) {
    spec = vec3(0.0);
  }

 
  if (isMetal) {
    kD *= 0.0;
  }
  
  
  

  
  // add to outgoing radiance Lo

  Lo = (kD* albedo  + spec) * diff * radiance * NdotL;

  indirect *= albedo / PI;

  return Lo + indirect;
}

#endif
