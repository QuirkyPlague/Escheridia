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

// https://advances.realtimerendering.com/s2017/DecimaSiggraph2017.pdf
float getNoHSquared(float NoL, float NoV, float VoL, float radius) {
  float radiusCos = cos(radius);
  float radiusTan = tan(radius);

  float RoL = 2.0 * NoL * NoV - VoL;
  if (RoL >= radiusCos) return 1.0;

  float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
  float NoTr = rOverLengthT * (NoV - RoL * NoL);
  float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

  float triple = sqrt(
    clamp(
      1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL,
      0.0,
      1.0
    )
  );

  float NoBr = rOverLengthT * triple,
    VoBr = rOverLengthT * (2.0 * triple * NoV);
  float NoLVTr = NoL * radiusCos + NoV + NoTr,
    VoLVTr = VoL * radiusCos + 1.0 + VoTr;
  float p = NoBr * VoLVTr,
    q = NoLVTr * VoLVTr,
    s = VoBr * NoLVTr;
  float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
  float xDenom =
    p * p +
    s * (s - 2.0 * p) +
    NoLVTr *
      ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr +
        q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
  float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
  float sinTheta = twoX1 * xDenom;
  float cosTheta = 1.0 - twoX1 * xNum;
  NoTr = cosTheta * NoTr + sinTheta * NoBr;
  VoTr = cosTheta * VoTr + sinTheta * VoBr;

  float newNoL = NoL * radiusCos + NoTr;
  float newVoL = VoL * radiusCos + VoTr;
  float NoH = NoV + newNoL;
  float HoH = 2.0 * newVoL + 2.0;
  return clamp(NoH * NoH / HoH, 0.0, 1.0);
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

  currentSunlight *= 21.0;
  vec3 radiance = currentSunlight * shadow * attenuation;

  
  float NdotL = clamp(dot(N, L), 0.0, 1.0);
  float NdotV = clamp(dot(N, V), 0.0, 1.0);
  float NdotH = clamp(dot(N, V), 0.0, 1.0);
  float VdotH = clamp(dot(V, H), 0.0, 1.0);
  float VdotL = clamp(dot(V,L), 0.0, 1.0);
  vec3 F = fresnelSchlick(max(dot(H, V), 0.0001), F0);

  float sunAngularRadius = 0.2 * PI / 180.0;
  // cook-torrance brdf
  float NdotH2 = getNoHSquared(NdotL, NdotV, VdotL,sunAngularRadius);
  float alpha = max(1e-3,roughness);
  float NDF = DistributionGGX(N, H, alpha);
  float G = GeometrySmith(N, V, L, alpha);

  vec3 numerator = NDF * G * F ;
  float denominator = 4.0 * NdotV * NdotL + 0.0001;
  vec3 spec = numerator / denominator;
  
 spec = min(spec, vec3(25.0));
 if(isMetal) spec = min(spec, vec3(2.6));
 
 
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

  Lo = (kD * albedo  + spec) * diff * radiance * NdotL;
  indirect *= albedo / PI;

  return Lo + indirect;
}

#endif
