#ifndef WATER_FOG_GLSL
#define WATER_FOG_GLSL 1 //[0 1]

#include "/lib/util.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"



const vec3 WATER_ABOSRBTION = vec3(ABSORPTION_R, ABSORPTION_G, ABSORPTION_B);
const vec3 WATER_SCATTERING = vec3(SCATTER_R, SCATTER_G, SCATTER_B);

vec3 waterExtinction(
  vec3 color,
  vec2 texcoord,
  vec2 lightmap,
  float depth,
  float depth1
) {
  float dist0 = length(screenToView(texcoord, depth));
  float dist1 = length(screenToView(texcoord, depth1));
  float dist = max(0, dist1 - dist0);
  vec3 sunColor = vec3(0.0);
  sunColor = vec3(1.0, 0.898, 0.698);
  if (inWater) {
    dist = dist0;
  }
  vec3 absorptionColor = vec3(0.0);
  vec3 absorption = WATER_ABOSRBTION;
  vec3 inscatteringAmount = vec3(0.0);
  inscatteringAmount = WATER_SCATTERING;
  inscatteringAmount *= SCATTER_COEFF;
  inscatteringAmount *= eyeBrightnessSmooth.y;
  inscatteringAmount *= 0.005;
 
  vec3 absorptionFactor = exp(
    -absorption * WATER_FOG_DENSITY * (dist * ABSORPTION_COEFF)
  );

  color *= absorptionFactor;
  color +=
    sunColor *
    inscatteringAmount /
    absorption *
    (1.0 - clamp(absorptionFactor, 0, 1));

  return color;
}
vec3 waterFog(vec3 color, vec2 texcoord, vec2 lightmap, float depth) {
  float dist0 = length(screenToView(texcoord, depth)) / 3;

  float dist = dist0;
  vec3 sunColor = vec3(0.0);
  sunColor = vec3(1.0, 0.898, 0.698);
  vec3 absorptionColor = vec3(0.0);
  vec3 absorption = WATER_ABOSRBTION;
  vec3 inscatteringAmount = vec3(0.0);
  inscatteringAmount = WATER_SCATTERING;
  inscatteringAmount *= SCATTER_COEFF;
 
  vec3 absorptionFactor = exp(
    -absorption * UNDERWATER_FOG_DENSITY * (dist * ABSORPTION_COEFF)
  );
  color.rgb *= absorptionFactor;
  color.rgb += inscatteringAmount / absorption * (1.0 - absorptionFactor);

  return color.rgb;
}

#endif //WATER_FOG_GLSL
