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

vec3 traceFog(vec3 worldPos, vec3 color, inout vec4 history, vec2 texcoord)
{
  float t=fract(worldTime/24000.);
    const int keys=7;
    const float keyFrames[keys]=float[keys](
        0.,//sunrise
        .0417,//day
        .45,//noon
        .5192,//sunset
        .5417,//night
        .9527,//midnight
        1.0//sunrise
    );
    
    const float morningFogPhase=MORNING_PHASE;
    const float dayFogPhase=DAY_PHASE;
    const float noonFogPhase=NOON_PHASE;
    const float eveningFogPhase=EVENING_PHASE;
    const float nightFogPhase=NIGHT_PHASE;
    
    const float fogPhase[keys]=float[keys](
        morningFogPhase,
        dayFogPhase,
        noonFogPhase,
        eveningFogPhase,
        nightFogPhase,
        nightFogPhase,
        morningFogPhase
    );
    const float intensity[keys]=float[keys](
        0.65,
        1.0,
        1.0,
        0.65,
        0.35,
        0.35,
        0.65
    );
    
    int i=0;
    //assings the keyframes
    for(int k=0;k<keys-1;++k){
        i+=int(step(keyFrames[k+1],t));
    }
    i=clamp(i,0,keys-2);
    
    //Interpolation factor based on the time
    float timeInterp=
    (t-keyFrames[i])/max(1e-6,keyFrames[i+1]-keyFrames[i]);
    timeInterp=smoothstep(0.,1.,timeInterp);
    
    float phaseVal=mix(fogPhase[i],fogPhase[i+1],timeInterp);
    float skyIntensity=mix(intensity[i],intensity[i+1],timeInterp);

    //Constants
    const float UNIFORM_PHASE=1./(4.*PI);
    const float _StepSize=  STEP_SIZE;
    const float _NoiseOffset=12.05;
    const float MULTI_SCATTER_GAIN= MS_POWER;// how much single scatter feeds MS
    const float MULTI_SCATTER_DECAY= MS_FALLOFF;// energy loss per step

    //Raymarching parameters
    vec3 entryPoint=cameraPosition;
    vec3 viewDir=worldPos-cameraPosition;
    vec3 eyePos = viewDir - gbufferModelViewInverse[3].xyz;
    float viewLength=length(eyePos);
    vec3 rayDir=normalize(eyePos);
    float distLimit=min(viewLength,TRACING_DISTANCE);
    vec3 noise = blue_noise(floor(gl_FragCoord.xy), frameCounter);
    float distTravelled=noise.x*_NoiseOffset;

    //Volumetric parameters
    float scatterReduce=smoothstep(0,185,eyeBrightnessSmooth.y);
    vec3 lightScattering=vec3(16.) * PHASE_MULTIPLIER;
    vec3 absCoeff = vec3(1.0, 1.0, 1.0);
    float transmittance= 1.0;
    vec3 multiScatterEnergy=vec3(0.);

    //Colors for fog
    vec3 jungleCol = vec3(0.5373, 0.8196, 0.7451)  / (4 * PI);
    vec3 jungleTint = vec3(0.7412, 0.9333, 0.642) * 1.45 ;
    vec3 fogCol=computeSkyColoring(vec3(0.))  / (4 * PI);
    vec3 sunCol=currentSunColor(vec3(0.));
    sunCol = mix(sunCol, sunCol * jungleTint, jungleSmooth);
    fogCol = mix(fogCol, jungleCol * 0.9, jungleSmooth);
    fogCol *= 21; //boost to ambient strength
    float fogLum = luminance(fogCol * skyIntensity);
    fogCol *= fogLum;
    
    fogCol = mix(fogCol, WATER_SCATTERING * 0.81, float(inWater));
    absCoeff = mix(absCoeff, WATER_ABOSRBTION * 4, float(inWater));

   //Shadow filter radius and bias calculation
    const float shadowMapPixelSize=1./float(SHADOW_RESOLUTION);
    vec3 biasAdjustFactor=vec3(
        shadowMapPixelSize*1.,
        shadowMapPixelSize*1.,
    -.0003803515625);
    float sampleRadius=SHADOW_SOFTNESS*shadowMapPixelSize*.34;
    while(distTravelled<distLimit)
    {
      vec3 rayPos=entryPoint+rayDir*distTravelled;
      vec3 shadowRayPos=rayDir*distTravelled;
      float density=getFogDensity(rayPos);
      if(density > 0.0)
      {
        //Generate shadow coord then apply pcf 
        //Not the most efficient but it works
        vec4 shadowClip=getShadowClipPos(shadowRayPos);
        vec3 shadow=vec3(0.0);
        for(int s=0;s<3;s++)
        {
          vec2 offset=vogelDisc(s,3,noise.x)*sampleRadius;
          vec4 offsetShadowClipPos=shadowClip+vec4(offset,0.,0.);
          offsetShadowClipPos.xyz=distortShadowClipPos(offsetShadowClipPos.xyz);// apply distortion
          vec3 shadowNDCPos=offsetShadowClipPos.xyz/offsetShadowClipPos.w;// convert to NDC space
          vec3 shadowScreenPos=shadowNDCPos*.5+.5;// convert to screen space
          shadow+=getShadow(shadowScreenPos);// take shadow sample
          }
        shadow/=float(3);
        //get the transmittance along the density
        transmittance*= exp(float(-absCoeff) * density * _StepSize);
        //Calculate directional lighting for the fog
        vec3 lightDir=worldLightVector;
        float phase=CS(phaseVal,dot(rayDir,lightDir)) + 0.13 * CS(-0.1,dot(rayDir,lightDir));
        phase = mix(phase,waterPhase(dot(rayDir,lightDir)),float(inWater));
        vec3 directLight=sunCol*shadow;

        //Calculate the energy falloff of the phase function per the density
        //We are also going to calculate the overall power of the scattering as well as set up the multiscatter phase
        float energy = exp(-density) * phase;
        float scatter=density*_StepSize*transmittance;
        float msFactor=clamp(1.-transmittance,0.,1.);
        float msPhase=mix(energy,UNIFORM_PHASE,msFactor);
        float scattering = 1.0 * density;

        //Calculate the total scattering factor
        vec3 singleScatter = energy * scatter * (directLight*lightScattering);
        multiScatterEnergy += singleScatter * MULTI_SCATTER_GAIN* density;
        multiScatterEnergy *= MULTI_SCATTER_DECAY;
        vec3 multiScatter=multiScatterEnergy*msPhase*scatter;
        vec3 totalScattering = singleScatter + multiScatter;

        //Now calculate the scattering integral
        vec3 sampleExtinction = ( totalScattering + absCoeff );
        fogCol += (totalScattering - totalScattering * transmittance) / sampleExtinction;
         transmittance*=exp(-density*_StepSize);
        }
        distTravelled+=_StepSize;
      }

      //reproject fog color

       #if TEMPORAL_REPROJECTION == 1
    {
    float depthCheck = texture(depthtex0, texcoord).r;
    float opaqueDepth = texture(depthtex1, texcoord).r;
    const float handDepth = MC_HAND_DEPTH * 0.5 + 0.5;
    history.a = screenSpaceToViewSpace(opaqueDepth);
      // reproject current pixel
      vec3 screenPos = vec3(texcoord.xy, depthCheck);
      vec3 NDCPos = screenPos * 2.0 - 1.0;
      vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
      vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
      feetPlayerPos += cameraPosition;
      feetPlayerPos -= previousCameraPosition;
      vec3 previousView = (gbufferPreviousModelView * vec4(feetPlayerPos, 1.0)).xyz;
      vec4 previousClip = gbufferPreviousProjection * vec4(previousView, 1.0);
      vec3 previousScreen = (previousClip.xyz / previousClip.w) * 0.5 + 0.5;
      vec2 prevCoord = previousScreen.xy;
      vec3 currentPreviousView = previousView;
      depthCheck = screenSpaceToViewSpace(depthCheck);
      vec4 historyColor = texture(colortex13, prevCoord);
       currentPreviousView.z = screenSpaceToViewSpace(historyColor.a);
      // rejection checks
      bool historyRejection = clamp(prevCoord, 0, 1) != prevCoord;
     historyRejection || distance(previousView, currentPreviousView) > 0.1;
      float prevDepth = texture(depthtex0, prevCoord).r;

       float sampleNDCDepth = depthCheck * 2.0 - 1.0;
        float sampleViewDepth = gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * sampleNDCDepth + gbufferProjectionInverse[3].w);
      float prevViewZ = projectAndDivide(gbufferProjectionInverse, vec3(prevCoord, prevDepth) * 2.0 - 1.0).z;
      float depthDelta = abs(depthCheck - prevViewZ);
      float depthThreshold = max(0.01, abs(sampleViewDepth) * 0.01);
      float depthConfidence = pow(clamp(1.0 - depthDelta / depthThreshold, 0, 1), 1.0);
            float factor = 0.45;
             bool rejectHistory = false;
            if(depthCheck <= 0.56 )rejectHistory = true; 
         if(prevDepth <= 0.56 )rejectHistory = true;
           
            float historyWeight = factor * float(!historyRejection) * float(!rejectHistory) * depthConfidence;
            
            fogCol = mix(fogCol, historyColor.rgb, historyWeight);
            if (any(isnan(fogCol))) fogCol = vec3(0.0);
        
    }
        // write history buffer (colortex13) for next frame
    history = vec4(fogCol,0.0);
    #endif
      color = mix(color,fogCol,1.-clamp(transmittance,0,1));
      return color;
    }
#endif //VOLUMETRICS_GLSL
