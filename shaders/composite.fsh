#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/util.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 3 */
layout(location = 0) out vec4 color;

void main() {
  float depth = texture(depthtex0, texcoord).r;
  float depth1 = texture(depthtex1, texcoord).r;

  //space conversions
  vec3 screenPos = vec3(texcoord.xy, depth);
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec4 waterMask = texture(colortex4, texcoord);
  int blockID = int(waterMask) + 100;
  bool isWater = blockID == WATER_ID;
  float jitter = IGN(gl_FragCoord.xy, frameCounter);
  int stepCount = GODRAYS_SAMPLES;

  #if VOLUMETRIC_LIGHTING == 1
  color.rgb = sampleGodrays(color.rgb, texcoord, feetPlayerPos, depth);

  #elif VOLUMETRIC_LIGHTING == 2

  const float shadowMapPixelSize = 1.0 / float(SHADOW_RESOLUTION);
  float sampleRadius = SHADOW_SOFTNESS * shadowMapPixelSize * 0.74;
  #if PIXELATED_LIGHTING == 1
  sampleRadius = SHADOW_SOFTNESS * shadowMapPixelSize * 0.54;

  feetPlayerPos = feetPlayerPos + cameraPosition;
  feetPlayerPos = floor(feetPlayerPos * 8 + 0.01) / 8;
  feetPlayerPos -= cameraPosition;
  #endif
  vec3 shadowViewPos_start = (shadowModelView * vec4(vec3(0.0), 1.0)).xyz;
  vec4 shadowClipPos_start = shadowProjection * vec4(shadowViewPos_start, 1.0);
  vec3 shadowNDCPos_start = shadowClipPos_start.xyz / shadowClipPos_start.w;
  vec3 shadowScreenPos_start = shadowNDCPos_start * 0.5 + 0.5;

  vec3 shadowViewPos_end = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos_end = shadowProjection * vec4(shadowViewPos_end, 1.0);
  vec3 shadowNDCPos_end = shadowClipPos_end.xyz / shadowClipPos_end.w;
  vec3 shadowScreenPos_end = shadowNDCPos_end * 0.5 + 0.5;
  float inverseStep = 1.0 / float(stepCount);
  vec4 shadowStepSize = (shadowClipPos_end - shadowClipPos_start) * inverseStep;
  vec4 shadowPos = shadowClipPos_start + jitter * shadowStepSize;

  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
  vec3 worldPos = eyePlayerPos + cameraPosition;

  
   float minHeight = VOLUMETRIC_MIN_HEIGHT;
  float maxHeight = VOLUMETRIC_MAX_HEIGHT;


  float farPlane = far /4;
  float dist = clamp(length(eyePlayerPos), 0.0, far);

  float waveFalloff = length(eyePlayerPos) / far;
  float waveIntensityRolloff = exp(0.8 * WAVE_INTENSITY * (0.05 - waveFalloff));

  vec3 scatterF = vec3(0.0015, 0.0021, 0.0045);

  vec3 absorbF = vec3(0.2863, 0.4941, 0.9412);
  if (inWater) {
    scatterF = WATER_SCATTERING  ;
    absorbF = WATER_ABOSRBTION;
  }

  if (isNight) {
  
    absorbF = vec3(0.7412, 0.7412, 0.7412) * 3.15;
  }
  vec3 transmission = vec3(1.0);
  vec3 scatter = vec3(0.0, 0.0, 0.0);
  vec3 shadow;
  float VoL = dot(normalize(feetPlayerPos), worldLightVector);
  vec3 sunColor;
  sunColor = currentSunColor(sunColor);
  float  phase = 0.6 * CS(VL_ANISO, VoL) + 0.73 * CS(VL_ANISO_BACK, VoL);
  if (worldTime < 1000) {
    float t = smoothstep(0.0, 1000.0, float(worldTime));;
    scatterF *= mix(1.02, 1.0, t);
  } else if (worldTime < 24000) {
    float t = smoothstep(13000.0, 24000.0, float(worldTime));
    scatterF = mix(scatterF, vec3(0.251, 0.251, 0.251), t);

    scatterF *= mix(1.0, 1.5, t);
  } else {
    phase = 0.5 * CS(VL_ANISO, VoL) + 0.53 * CS(-0.35, VoL);
  }

 

  float worldSmooth = smoothstep(maxHeight, minHeight, worldPos.y);

  for (int i = 0; i < GODRAYS_SAMPLES; i++) {
    shadowPos += shadowStepSize;

    #if DO_VL_PCF == 1
    for (int i = 0; i < SHADOW_SAMPLES; i++) {
      vec2 offset = vogelDisc(i, SHADOW_SAMPLES, jitter) * sampleRadius;
      vec4 offsetShadowClipPos = shadowPos + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadow += getShadow(shadowScreenPos);
    }
    shadow /= float(SHADOW_SAMPLES); // divide sum by count, getting average shadow
    #else
    vec4 distortedShadowPos = shadowPos;
    distortedShadowPos.xyz = distortShadowClipPos(distortedShadowPos.xyz);
    vec3 shadowNDC = distortedShadowPos.xyz;
    vec3 shadowScreen = shadowNDC * 0.5 + 0.5;
    shadow = getShadow(shadowScreen);
    #endif

    transmission *= exp(-absorbF * dist);

    vec3 sampleInscatter = scatterF * phase * dist * sunColor * shadow;
    #ifdef DO_FOG_HEIGHT
    sampleInscatter *=
      mix(sampleInscatter * 4, sampleInscatter * 12.5, worldSmooth) *
      waveIntensityRolloff;
    #endif
    vec3 sampleExtinction = absorbF * VOLUMETRIC_FOG_DENSITY;
    float sampleTransmittance = exp(-dist * VOLUMETRIC_FOG_DENSITY  * 0.1 );
    scatter +=
      (sampleInscatter - sampleInscatter * sampleTransmittance) /
      sampleExtinction;
    transmission *= sampleTransmittance;

  }

  scatter *= 0.1;
 
  color.rgb = mix(color.rgb, transmission + scatter, 1.0 + wetness);
  if (depth == 1) {
    #ifdef DO_FOG_HEIGHT
    color.rgb = mix(color.rgb, (transmission + scatter), 1.0 + wetness);
    #else
    color.rgb = mix(color.rgb, (transmission + scatter) * 0.405, 1.0 + wetness);
    #endif
  }

  #endif

}

