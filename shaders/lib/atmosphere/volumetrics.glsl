#ifndef VOLUMETRICS_GLSL
#define VOLUMETRICS_GLSL

#include "/lib/shadows/drawShadows.glsl"
#include "/lib/util.glsl"



vec3 volumetricRaymarch(
  vec4 startPos,
  vec4 endPos,
  int stepCount,
  float jitter,
  vec3 feetPlayerPos,
  vec3 sceneColor
) {
  vec4 rayPos = endPos - startPos;
  vec4 stepSize = rayPos * (1.0 / stepCount);
  float rayLength = clamp(length(feetPlayerPos) + 1, 0, far / 2);
  vec4 stepLength = startPos + jitter * stepSize;
  const float shadowMapPixelSize = 1.0 / float(SHADOW_RESOLUTION);
  float sampleRadius = SHADOW_SOFTNESS * shadowMapPixelSize * 0.74;
  #if PIXELATED_LIGHTING == 1
  sampleRadius = SHADOW_SOFTNESS * shadowMapPixelSize * 0.54;

  feetPlayerPos = feetPlayerPos + cameraPosition;
  feetPlayerPos = floor(feetPlayerPos * 8 + 0.01) / 8;
  feetPlayerPos -= cameraPosition;
  #endif

  vec3 absCoeff = vec3(1.0);
  vec3 scatterCoeff = vec3(0.0019, 0.0012, 0.0013);

  if(inWater)
  {
    absCoeff = WATER_ABOSRBTION * 0.6;
  }
  vec3 scatter = vec3(0.0);
  vec3 transmission = vec3(1.0);

  float VdotL = dot(normalize(feetPlayerPos), worldLightVector);
  float phase =
    VL_FRONTSCATTER_INTENSITY * CS(VL_ANISO, VdotL) +
    VL_BACKSCATTER_INTENSITY * CS(VL_ANISO_BACK, VdotL);
  vec3 sunColor;

  vec3 shadow;
  for (int i = 0; i < stepCount; i++) {
    stepLength += stepSize;
    #if DO_VL_PCF == 1
    for (int i = 0; i < 5; i++) {
      vec2 offset = vogelDisc(i, 5, jitter) * sampleRadius;
      vec4 offsetShadowClipPos = stepLength + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadow += getShadow(shadowScreenPos);
    }
    shadow /= float(5); // divide sum by count, getting average shadow
    #else
    vec4 distortedShadowPos = stepLength;
    distortedShadowPos.xyz = distortShadowClipPos(distortedShadowPos.xyz);
    vec3 shadowNDC = distortedShadowPos.xyz;
    vec3 shadowScreen = shadowNDC * 0.5 + 0.5;
    shadow = getShadow(shadowScreen);
    #endif
    sunColor = currentSunColor(sunColor);
    transmission *= exp(-absCoeff * rayLength);
    vec3 sampleInscatter = scatterCoeff * phase * rayLength * sunColor * shadow;

    vec3 sampleExtinction = absCoeff * VOLUMETRIC_FOG_DENSITY;
    float sampleTransmittance = exp(-rayLength * VOLUMETRIC_FOG_DENSITY * 0.5);
    scatter +=
      (sampleInscatter - sampleInscatter * sampleTransmittance) /
      sampleExtinction;
    transmission *= sampleTransmittance;
  }
  scatter *= 0.135;
  return mix(sceneColor, transmission + scatter, 1.0 + wetness);
}
#endif //VOLUMETRICS_GLSL
