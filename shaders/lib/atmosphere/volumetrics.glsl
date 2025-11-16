#ifndef VOLUMETRICS_GLSL
#define VOLUMETRICS_GLSL

#include "/lib/shadows/softShadows.glsl"
#include "/lib/util.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/tonemapping.glsl"

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

  const float morningFogPhase = MORNING_PHASE;
  const float dayFogPhase = DAY_PHASE;
  const float noonFogPhase = NOON_PHASE;
  const float eveningFogPhase = EVENING_PHASE;
  const float nightFogPhase = NIGHT_PHASE;

  const float fogPhase[keys] = float[keys](
    morningFogPhase,
    dayFogPhase,
    noonFogPhase,
    eveningFogPhase,
    nightFogPhase,
    nightFogPhase,
    morningFogPhase
  );

   const float rainFog[keys] = float[keys](
    1.55,
    0.75,
    0.85,
    0.75,
    1.15,
    1.15,
    0.84

  );
  const float ambientI[keys] = float[keys](0.5, 1.0, 1.0, 0.5, 0.15, 0.15, 0.5);
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

  float phaseVal = mix(fogPhase[i], fogPhase[i + 1], timeInterp);
  float rain = mix(rainFog[i], rainFog[i + 1], timeInterp);
  float ambientIntensity = mix(ambientI[i], ambientI[i + 1], timeInterp);
  vec4 rayPos = endPos - startPos;
  vec4 stepSize = rayPos * (1.0 / stepCount);
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
  vec3 worldPos = feetPlayerPos + cameraPosition;
  float rayLength = clamp(length(eyePlayerPos) + 1, 0, far / 2);
  vec4 stepLength = startPos + (jitter + 0.5) * stepSize;
 const float falloffScale = 0.001 / log(2.0);
  float fogMaxHeight = smoothstep(-32, 64, worldPos.y);

  vec3 absCoeff = vec3(0.5255, 0.5255, 0.5255);
  vec3 scatterCoeff = vec3(0.00335, 0.00291, 0.00271);

  //absCoeff = mix(absCoeff, vec3(1.0), PaleGardenSmooth);
  scatterCoeff = mix(scatterCoeff, vec3(0.00715), PaleGardenSmooth);

  scatterCoeff = mix(scatterCoeff, vec3(0.0040, 0.0043, 0.00519), wetness);

  if (inWater) {
    absCoeff = WATER_ABOSRBTION * 1.15;
    scatterCoeff = WATER_SCATTERING * 0.35;
  }

  vec3 scatter = vec3(0.0);
  vec3 transmission = vec3(1.0);

  float VdotL = dot(normalize(feetPlayerPos), worldLightVector);
  float phaseIncFactor = smoothstep(225, 0, eyeBrightnessSmooth.y);
  float phaseMult = mix(1.0, 8.0, phaseIncFactor);
  if(inWater)
  {
    phaseMult = 1.0;
  }
  float ambientMult = mix(1.0, 0.0, phaseIncFactor);
  float phase =
    henyeyGreensteinPhase(VdotL, phaseVal) * FORWARD_PHASE_INTENSITY +
    henyeyGreensteinPhase(VdotL, -0.15) * BACKWARD_PHASE_INTENSITY * 0.55;

  phase = mix(phase,henyeyGreensteinPhase(VdotL, 0.65) * rain +
    henyeyGreensteinPhase(VdotL, -0.15) * rain, wetness);
  phase *= phaseMult;

 

  vec3 sunColor;

  sunColor = currentSunColor(sunColor);
   const float shadowMapPixelSize = 1.0 / float(SHADOW_RESOLUTION);
  
    vec3 biasAdjustFactor = vec3(
    shadowMapPixelSize * 1.0,
    shadowMapPixelSize * 1.0,
    -0.0003803515625
  );
  float sampleRadius = SHADOW_SOFTNESS * shadowMapPixelSize * 0.54;
  vec3 shadowNormal = mat3(shadowModelView) * normal;

  vec3 shadow;
  for (int i = 0; i < stepCount; i++) {
    stepLength += stepSize;
    
    for (int s = 0; s < 5; s++) {
      vec2 offset = vogelDisc(s, 5, jitter) * sampleRadius;
      vec4 offsetShadowClipPos = stepLength + vec4(offset, 0.0, 0.0);
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz);
      vec3 shadowNDCPos = offsetShadowClipPos.xyz;
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
      shadowScreenPos += shadowNormal * biasAdjustFactor;
      shadow += getShadow(shadowScreenPos);
    }
    shadow /= float(5);

    transmission *= exp(-absCoeff * length(stepLength) * 0.3);

    // --- Ambient lighting ---
    vec3 ambientFogColor =
      sceneColor * 0.025 + vec3(0.1059, 0.1216, 0.1373) * AMBIENT_FOG_MULT;
    ambientFogColor = mix(
      ambientFogColor,
      vec3(0.1922, 0.1922, 0.1922),
      wetness
    );
    vec3 ambient = vec3(0.0);
    if(!inWater)
    {
      ambient = ambientFogColor * 0.25 * ambientMult * ambientIntensity * (rain * 0.65);
    }
    // --- Direct inscattering ---
    vec3 singleScatter = scatterCoeff * phase * rayLength * sunColor * shadow;

    vec3 multipleScatter =
      singleScatter * 1.0 * MULTI_SCATTER_INTENSITY * (1.0 - transmission) ;

 

    vec3 sampleExtinction = (absCoeff + multipleScatter) * VL_EXT;
    float sampleTransmittance = exp(-length(stepLength) * 1.0);

    // combine single + multiple scattering
    vec3 totalInscatter = singleScatter + multipleScatter;

    scatter +=
      (totalInscatter - totalInscatter * sampleTransmittance) /
      sampleExtinction;
    transmission *= sampleTransmittance;
  }

  scatter *= 0.065;
  vec3 totalScatter = scatter + transmission ;
    float skyLuminance = dot(totalScatter, vec3(1.0));
	totalScatter = pow(totalScatter, vec3(1.5));
	totalScatter *= skyLuminance / dot(totalScatter, vec3(1.0));
  return totalScatter;
}
#endif //VOLUMETRICS_GLSL
