#ifndef VOLUMETRICS_GLSL
#define VOLUMETRICS_GLSL

#include "/lib/shadows/softShadows.glsl"
#include "/lib/util.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/lighting/lighting.glsl"

vec3 volumetricRaymarch(
  vec4 startPos,
  vec4 endPos,
  int stepCount,
  float jitter,
  vec3 feetPlayerPos,
  vec3 sceneColor,
  vec3 normal,
  vec2 lightmap
) {
  vec4 rayPos = endPos - startPos;
  vec4 stepSize = rayPos * (1.0 / stepCount);
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
  vec3 worldPos = feetPlayerPos + cameraPosition;
  float rayLength = clamp(length(eyePlayerPos) + 1, 0, far / 2);
  vec4 stepLength = startPos + jitter * stepSize;
  const float shadowMapPixelSize = 1.0 / float(SHADOW_RESOLUTION);
  float sampleRadius = SHADOW_SOFTNESS * shadowMapPixelSize * 0.54;

  #if PIXELATED_LIGHTING == 1
    sampleRadius = SHADOW_SOFTNESS * shadowMapPixelSize * 0.54;
    feetPlayerPos = feetPlayerPos + cameraPosition;
    feetPlayerPos = floor(feetPlayerPos * 8 + 0.01) / 8;
    feetPlayerPos -= cameraPosition;
  #endif

  vec3 absCoeff = vec3(0.6039, 0.7451, 0.9059);
  vec3 scatterCoeff = vec3(0.00375, 0.00331, 0.00291);
  
  absCoeff = mix(absCoeff, vec3(1.0), PaleGardenSmooth);
  scatterCoeff = mix(scatterCoeff, vec3(0.00715), PaleGardenSmooth);

  if (inWater) {
    absCoeff = WATER_ABOSRBTION * 2.39;
    scatterCoeff = WATER_SCATTERING * 0.02;
  }

  vec3 scatter = vec3(0.0);
  vec3 transmission = vec3(1.0);

  float VdotL = dot(normalize(feetPlayerPos), worldLightVector);
  float phaseIncFactor = smoothstep(225, 0, eyeBrightnessSmooth.y);
  float phaseMult = mix(1.0, 21.0, phaseIncFactor);
  float phase = evalDraine(VdotL, 0.635, 1118.1); 
  phase *= phaseMult;

  float rayleigh = Rayleigh(VdotL);

  vec3 sunColor;
  sunColor = currentSunColor(sunColor);

  vec3 biasAdjustFactor = vec3(
    shadowMapPixelSize * 2.45,
    shadowMapPixelSize * 2.45,
    -0.00003803515625
  );
  vec3 shadowNormal = mat3(shadowModelView) * normal;

  vec3 shadow;
  for (int i = 0; i < stepCount; i++) {
    stepLength += stepSize;

  
    for (int i = 0; i < 5; i++) {
      vec2 offset = vogelDisc(i, 5, jitter) * sampleRadius;
      vec4 offsetShadowClipPos = stepLength + vec4(offset, 0.0, 0.0);
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz);
      vec3 shadowNDCPos = offsetShadowClipPos.xyz;
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
      shadow += getShadow(shadowScreenPos);
    }
    shadow /= 5.0;
  
  
    transmission *= exp(-absCoeff * rayLength);

    
    vec3 sampleInscatter = scatterCoeff * phase * rayLength * sunColor * shadow;

    vec3 msLight = sunColor * (0.35 + 0.65 * shadow);  
    vec3 multiScatter = scatterCoeff * msLight * 0.25 * phaseMult; 
    multiScatter *= exp(-absCoeff * (float(i) / stepCount)); 

    vec3 ambientFog = sceneColor * 0.025 + vec3(0.05, 0.06, 0.07); 

    // Combine scattering effects
    vec3 sampleExtinction = absCoeff * 1.0;
    float sampleTransmittance = exp(-rayLength * 1.0 * 0.5);

    scatter += ((sampleInscatter + multiScatter + ambientFog * 0.135)
               - (sampleInscatter * sampleTransmittance))
               / sampleExtinction;

    transmission *= sampleTransmittance;
  }

  
  scatter *= 0.135;
  scatter = mix(scatter, normalize(scatter), 0.035); 
  scatter = clamp(scatter, 0.0, 6.5);

  return scatter + transmission;
}
#endif //VOLUMETRICS_GLSL
