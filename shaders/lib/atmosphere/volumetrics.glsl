#ifndef VOLUMETRICS_GLSL
#define VOLUMETRICS_GLSL

#include "/lib/shadows/softShadows.glsl"
#include "/lib/util.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/tonemapping.glsl"
#include "/lib/atmosphere/distanceFog.glsl"



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
    0.95,
    0.85,
    0.75,
    0.75,
    0.75,
    0.84

  );
  const float ambientI[keys] = float[keys](1.4, 1.64, 1.64, 1.3, 9.27, 9.27, 1.4);
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
  
  float rayLength = clamp(length(eyePlayerPos) + 1, 0, far);
  vec4 stepLength = startPos + (jitter + 0.5) * stepSize;
 const float falloffScale = 0.001 / log(2.0);
  float fogMaxHeight = smoothstep(157, 8, worldPos.y);
 
  vec3 absCoeff = vec3(0.4706, 0.5333, 0.6353);
  vec3 scatterCoeff = vec3(0.00335, 0.00291, 0.00231);

  //absCoeff = mix(absCoeff, vec3(1.0), PaleGardenSmooth);
  scatterCoeff = mix(scatterCoeff, vec3(0.00715), PaleGardenSmooth);

  scatterCoeff = mix(scatterCoeff, vec3(0.0040, 0.0043, 0.00519), wetness);
  
  if (inWater) {
    absCoeff = WATER_ABOSRBTION * 0.35;
    scatterCoeff = WATER_SCATTERING * 0.085;
  }

  vec3 scatter = vec3(0.0);
  vec3 transmission = vec3(1.0);

  float VdotL = dot(normalize(feetPlayerPos), worldLightVector);
  float phaseIncFactor = smoothstep(225, 0, eyeBrightnessSmooth.y);
  float scatterReduce = smoothstep(0, 185, eyeBrightnessSmooth.y);
  float phaseMult = 1.0;
 
  float ambientMult = mix(1.0, 0.0, phaseIncFactor);
   if(!inWater)
  {
   phaseMult = mix(1.0, 4.0, phaseIncFactor);
  }
  else{
    phaseMult = 1.0;
    ambientMult = 0.0;
  } 
  
  float phase =
    CS(phaseVal,VdotL) * FORWARD_PHASE_INTENSITY +
    CS(-0.25, VdotL) * BACKWARD_PHASE_INTENSITY * 0.85;

  phase = mix(phase,CS(0.65, VdotL) * rain +
    CS(-0.25, VdotL) * rain, wetness);
  phase *= phaseMult;

 if(inWater)
 {
    phase = CS(0.885, VdotL);
 }

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
      vec4 prevStep = stepLength;
    stepLength += stepSize;
    
    for (int s = 0; s < 3; s++) {
      vec2 offset = vogelDisc(s, 3, jitter) * sampleRadius;
      vec4 offsetShadowClipPos = prevStep + vec4(offset, 0.0, 0.0);
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
    vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
    vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
    shadowScreenPos += shadowNormal * biasAdjustFactor;
    shadow += getShadow(shadowScreenPos); // take shadow sample
    }
    shadow /= float(3);
    
    transmission *= exp(-absCoeff * length(stepLength));

   
    vec3 directLight = sunColor * shadow;              


  vec3 singleScatter = scatterCoeff * phase * rayLength * directLight * ambientIntensity ;
    
    vec3 msLight = sunColor * (0.35 + 0.63 * shadow);
    vec3 multiScatter = scatterCoeff * msLight * 45.0 * ambientMult; 
    multiScatter *= exp(-absCoeff * (float(i) / length(stepLength))); 

    vec3 sampleExtinction = (absCoeff + multiScatter) * VL_EXT;
    float sampleTransmittance = exp(-length(stepLength) * 1.0);

    // combine single + multiple scattering
    vec3 totalInscatter = singleScatter + multiScatter ;

    scatter +=
      (totalInscatter - totalInscatter * sampleTransmittance) /
      sampleExtinction;
    transmission *= sampleTransmittance;
    
  }
  float fogDistFalloff = length(feetPlayerPos) / far;
  float fogReduction = exp( 0.525 * (1.0 - fogDistFalloff));

  
 scatter *= 0.045 * fogReduction;
  vec3 totalScatter = scatter  ;

  return  mix(sceneColor, scatter, 1.0 - clamp(transmission,0,1));

}
#endif //VOLUMETRICS_GLSL
