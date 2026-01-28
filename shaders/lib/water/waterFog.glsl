#ifndef WATER_FOG_GLSL
#define WATER_FOG_GLSL 1 //[0 1]

#include "/lib/util.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/common.glsl"
#include "/lib/phaseFunctions.glsl"
#include "/lib/lighting/lighting.glsl"

const vec3 WATER_ABOSRBTION = vec3(ABSORPTION_R, ABSORPTION_G, ABSORPTION_B);
const vec3 WATER_SCATTERING = vec3(SCATTER_R, SCATTER_G, SCATTER_B);

vec3 waterExtinction(
  vec3 color,
  vec2 texcoord,
  vec2 lightmap,
  float depth,
  float depth1
) {
 
  float t = fract(worldTime / 24000.0);

  const int keys = 7;
  const float keyFrames[keys] = float[keys](
    0.0, //sunrise
    0.0417, //day
    0.45, //noon
    0.5192, //sunset
    0.5417, //night
    0.9527, //midnight
    1.0 //sunrise
  );

  const float fogIntensity[keys] = float[keys](
    0.85,
    1.0,
    1.0,
    0.85,
    0.025,
    0.025,
    0.85
  );
  int i = 0;
  //assings the keyframes
  for (int k = 0; k < keys - 1; ++k) {
    i += int(step(keyFrames[k + 1], t));
  }
  i = clamp(i, 0, keys - 2);

  //Interpolation factor based on the time
  float timeInterp =
    (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
  timeInterp = smoothstep(0.0, 1.0, timeInterp);

  float fog = mix(fogIntensity[i], fogIntensity[i + 1], timeInterp);

  float dist0 = length(screenToView(texcoord, depth));
  float dist1 = length(screenToView(texcoord, depth1));
  float dist = max(0, dist1 - dist0);
  vec3 sunColor = vec3(0.0);
  sunColor = currentSunColor(sunColor) * 5;
  if (inWater) {
    dist = dist0;
  }
  
  vec3 absorptionColor = vec3(0.0);
  vec3 absorption = WATER_ABOSRBTION;
  vec3 inscatteringAmount = vec3(0.0);
  inscatteringAmount = WATER_SCATTERING ;
  inscatteringAmount *= SCATTER_COEFF;
  inscatteringAmount *= fog;

  inscatteringAmount = pow(inscatteringAmount, vec3(2.2));
  absorption = pow(absorption, vec3(2.2));
   vec3 screenPos = vec3(texcoord.xy, depth);
  vec3 NDCPos = vec3(texcoord, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 viewDir = normalize(viewPos);
  float VdotL = dot(viewDir, lightVector);
   float phase = waterPhase(VdotL);
  float backPhase = henyeyGreensteinPhase(VdotL, -0.0);
float smoothDepth = smoothstep(0.998, 1.0, depth);
  float scatterReduce = smoothstep(0, 185, eyeBrightnessSmooth.y);
  float fogDistFalloff = length(viewPos) / far;
  float fogReduction = exp( 0.75 * (-2.5 - fogDistFalloff));
  vec3 phaseLighting = sunColor * phase * scatterReduce * fogReduction;
  vec3 scattering = inscatteringAmount  * backPhase ;
  vec3 totalScattering = (phaseLighting + scattering) * SCATTER_COEFF;
  vec3 absorptionFactor = exp(
    -absorption * WATER_FOG_DENSITY * (dist * ABSORPTION_COEFF * 3)
  );
  
  color *= absorptionFactor;
  color +=
    totalScattering /
    absorption *
    (1.0 - clamp(absorptionFactor, 0, 1));

   return color;
}
vec3 waterFog(vec3 color, vec2 texcoord, vec2 lightmap, float depth) {
  
  float dist0 = length(screenToView(texcoord, depth));

  float dist = dist0;
  vec3 sunColor = vec3(0.0);
  sunColor = currentSunColor(sunColor) * 0.7;
  vec3 absorptionColor = vec3(0.0);
  vec3 absorption = WATER_ABOSRBTION;
  vec3 inscatteringAmount = vec3(0.0);
  inscatteringAmount = WATER_SCATTERING * 3;
  inscatteringAmount *= SCATTER_COEFF;
  inscatteringAmount = pow(inscatteringAmount, vec3(2.2));
  absorption = pow(absorption, vec3(2.2));
  vec3 screenPos = vec3(texcoord.xy, depth);
  vec3 NDCPos = vec3(texcoord, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 viewDir = normalize(viewPos);
  float VdotL = dot(viewDir, lightVector);
  float phase = waterPhase(VdotL);
  float backPhase = henyeyGreensteinPhase(VdotL, -0.1);
  float smoothDepth = smoothstep(0.998, 1.0, depth);
   float scatterReduce = smoothstep(0, 185, eyeBrightnessSmooth.y);
    
  vec3 phaseLighting = sunColor * phase * scatterReduce;
  vec3 scattering = inscatteringAmount  * backPhase ;
  vec3 totalScattering = (phaseLighting + scattering) * SCATTER_COEFF;
  vec3 absorptionFactor = exp(
    -absorption * UNDERWATER_FOG_DENSITY * (dist * ABSORPTION_COEFF * 3)
  );
  color.rgb *= absorptionFactor;
   color.rgb += (totalScattering / absorption) * (1.0 - absorptionFactor) ;

  return color.rgb;
}

#endif //WATER_FOG_GLSL
