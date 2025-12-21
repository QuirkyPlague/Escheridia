#ifndef SOFTSHADOWS_GLSL
#define SOFTSHADOWS_GLSL

#include "/lib/util.glsl"
#include "/lib/common.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/distort.glsl"

vec4 getShadowClipPos(vec3 feetPlayerPos) {
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  return shadowClipPos;
}

vec3 getSoftShadow(vec4 shadowClipPos, vec3 normal, float SSS) {
  vec3 shadowNormal = mat3(shadowModelView) * normal ;
  const float shadowMapPixelSize = 1.0 / float(SHADOW_RESOLUTION);
  float sampleRadius = SHADOW_SOFTNESS * shadowMapPixelSize *0.45;
  vec3 biasAdjustFactor = vec3(
    shadowMapPixelSize * 1.75,
    shadowMapPixelSize * 1.75,
    -0.00007803515625
  );

  float faceNdl = dot(normal, worldLightVector);
  if (faceNdl <= 1e-6 && SSS > 64.0 / 255.0) {
    sampleRadius *= exp((0.3 + 3.2) * SSS);
  }

  vec3 shadowAccum = vec3(0.0); // sum of all shadow samples
 
     for (int i = 0; i < SHADOW_SAMPLES; i++) {
    vec3 noise = blue_noise(floor(gl_FragCoord.xy), frameCounter, int(i));
    vec2 offset = vogelDisc(i, SHADOW_SAMPLES, noise.x) * sampleRadius;
    vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
    offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
    vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
    vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
    shadowScreenPos += shadowNormal * biasAdjustFactor;
    shadowAccum += getShadow(shadowScreenPos); // take shadow sample
  }
  
 

  return shadowAccum / float(SHADOW_SAMPLES); // divide sum by count, getting average shadow
}

#endif // SOFTSHADOWS_GLSL
