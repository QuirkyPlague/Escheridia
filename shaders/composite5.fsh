#version 430 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/blockID.glsl"
#include "/lib/SSR.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/water/waves.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/clouds.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/tonemapping.glsl"
#include "/lib/postProcessing.glsl"
#include "/lib/bloom.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0,14 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 history;

mat3 tbnMatrix(vec3 N) {
  vec3 up = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
  vec3 T = normalize(cross(up, N));
  vec3 B = cross(N, T);
  return mat3(T, B, N);
}

vec3 skyFallbackBlend(
  vec3 dir,
  vec3 sunColor,
  vec3 viewPos,
  vec2 uv,
  vec3 normal,
  float roughness,
  bool isWater
) {
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
  normal = (gbufferModelViewInverse * vec4(normal, 1.0)).xyz;
  normal = normal - gbufferModelViewInverse[3].xyz;
  vec3 dir2;
  #ifdef ROUGH_REFLECTION

  mat3 tbn = tbnMatrix(normal);

  //view direction in tangent space
  vec3 tangentView = normalize(transpose(tbn) * normalize(-eyePlayerPos));

  vec3 accumulated = vec3(0.0);

  for (uint i = 0u; i < uint(ROUGH_SAMPLES); i++) {
    vec3 noise = blue_noise(floor(gl_FragCoord.xy), frameCounter, int(i));
    vec3 microFacit = SampleVNDFGGX(tangentView, vec2(roughness), noise.xy);

    vec3 tangentReflDir = reflect(-tangentView, microFacit);

    vec3 skyDir = normalize(tbn * tangentReflDir);

    vec3 skyCol = skyScattering(skyDir);
   
    accumulated += skyCol ;

  }
  vec3 sky = accumulated / float(ROUGH_SAMPLES);
  float waterOrZeroMask = float(isWater || roughness <= 0);
  vec3 altDir2 = reflect(eyePlayerPos, normal);
  vec3 altSkyCol = skyScattering(normalize(altDir2));
  vec3 altSunCol = getSun(normalize(altDir2));
  vec3 altSky = altSunCol + altSkyCol;

  dir2 = mix(dir2, altDir2, waterOrZeroMask);
  sky = mix(sky, altSky, waterOrZeroMask);
  #else
  dir2 = reflect(normalize(eyePlayerPos), normal);

  vec3 skyCol = skyScattering(dir2);
  vec3 sunCol = getSun(dir2);
  vec3 sky = sunCol + skyCol;

  #endif

  
  return sky;
}


void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex0, texcoord).r;
  if (depth == 1.0) return;
  float rain = texture(colortex8, texcoord).r;
  if(rain == 1.0) return;
  vec4 SpecMap = texture(colortex3, texcoord);
  vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec2 lightmap = texture(colortex1, texcoord).rg;
  vec4 waterM = texture(colortex5, texcoord);
  vec3 surfNorm = texture(colortex4, texcoord).rgb;
  vec3 geoNormal = normalize((surfNorm - 0.5) * 2.0);

  vec3 albedo = texture(colortex0, texcoord).rgb;
  
  int blockID = int(waterM) + 100;

  bool isWater = blockID == WATER_ID;
  bool isMetal = SpecMap.g >= 230.0 / 255.0;

  //Space conversions
  vec3 screenPos = vec3(texcoord.xy, depth);
  vec3 NDCPos = vec3(texcoord, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 viewDir = normalize(viewPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
 
  vec3 previousView = (gbufferPreviousModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 previousClip = gbufferPreviousProjection * vec4(previousView, 1.0);
  vec3 previousScreen = (previousClip.xyz / previousClip.w) * 0.5 + 0.5;
  vec2 prevCoord = previousScreen.xy;
  vec3 prevCol = texture(colortex9, prevCoord).rgb;
  vec3 prevViewDir = normalize(previousView);

  float farPlane = far / 0.75;
 
  
  vec3 worldPos = feetPlayerPos + cameraPosition;
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
  normal = mat3(gbufferModelView) * normal;

  vec2 noisePos = fract(worldPos.xz /64.0);
 

  const float handDepth = MC_HAND_DEPTH * 0.5 + 0.5;
  float flatness = max(dot(normalize(geoNormal), vec3(0.0, 1.0, 0.0)), 0.0);
  float baseRoughness = pow(1.0 - SpecMap.r, 2.0);
  float roughness = isWater ? 0.0 : baseRoughness;
  float smoothLightmap = clamp(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y),0,1);

  float handMask = step(handDepth, depth);
  float waterMaskF = float(!isWater);
  float rainFactor = clamp(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y), 0, 1) * wetness;
  rainFactor *= smoothstep(
    -0.15,
    0.75,
    texture(
      puddleTex,
      noisePos
    ).r
  ) * flatness * snowBiomeSmooth * hotBiomeSmooth;
  rainFactor *= handMask * waterMaskF;

  
 float waveNoise =  texture(waterTex,mod((feetPlayerPos.xz + cameraPosition.xz) / 2.0, 128.0) / 128.0).r;
  #ifdef WAVES
  if (isWater) {
    if(flatness >= 1e-6)
    {
      float waveFalloff = length(feetPlayerPos) / farPlane;
    float waveIntensityRolloff = exp(
      12.0 * WAVE_INTENSITY * (0.05 - waveFalloff)
    );
    float waveIntensity = 0.67 * WAVE_INTENSITY * waveIntensityRolloff;
    float waveSoftness = 0.13 * WAVE_SOFTNESS;

    normal = waveNormal(
      feetPlayerPos.xz + cameraPosition.xz,
      waveSoftness,
      waveIntensity
    );
    normal = mat3(gbufferModelView) * normal;
    }
  }
  if(inWater && isWater)
  {
       float waveFalloff = length(feetPlayerPos) / farPlane;
    float waveIntensityRolloff = exp(
      12.0 * WAVE_INTENSITY * (0.05 - waveFalloff)
    );
  float waveIntensity = 0.67 * WAVE_INTENSITY * waveIntensityRolloff;
    float waveSoftness = 0.2 * WAVE_SOFTNESS;

    normal = waveNormal(
      feetPlayerPos.xz + cameraPosition.xz,
      waveSoftness,
      waveIntensity
    );
    normal = mat3(gbufferModelView) * normal;
  }

   float waveFalloff = length(feetPlayerPos) / farPlane;
    float waveIntensityRolloff = exp(
      12.0 * WAVE_INTENSITY * (0.05 - waveFalloff)
    );
   float waveIntensity = 0.137 * WAVE_INTENSITY * waveIntensityRolloff;
    float waveSoftness = 0.018 * WAVE_SOFTNESS;

    vec3 rainNormal = rainNormals(
      feetPlayerPos.xz + cameraPosition.xz,
      waveSoftness,
      waveIntensity, rainFactor
    );
    rainNormal = mat3(gbufferModelView) * rainNormal;
    
      normal = mix(normal, rainNormal, rainFactor);
  #else
  // no additional normal modification for non-wave mode
  #endif

  // --- F0 and roughness
  vec3 f0 = vec3(SpecMap.g);
  f0 = mix(f0, vec3(0.02), float(isWater));
  f0 = mix(f0, albedo * 7, float(isMetal));
  f0 = mix(f0, vec3(1.0), float(inWater && isWater));
  
  f0 = mix(f0, vec3(0.02), rainFactor);
  float bRough = roughness;
  float wetRoughness = mix(roughness* 0.5, roughness * 0.01, rainFactor);
  

  roughness = mix(roughness,wetRoughness, wetness);
  
  bool canReflect = roughness < 1.0;
   

        
    
  
  float jitter = IGN(gl_FragCoord.xy, frameCounter);
  vec2 offset = vec2(0.0, 0.0);
  // --- Reflection vectors

  vec3 reflectedDir;
  #ifdef ROUGH_REFLECTION

  mat3 tbn = tbnMatrix(normal);

  //view direction in tangent space
  vec3 tangentView = normalize(transpose(tbn) * -viewDir);
  float NdoV = max(dot(normal, -tangentView), 0.0);
  vec3 accumulated = vec3(0.0);
  float ndotL = dot(normal, lightVector);
  
  for (uint i = 0u; i < uint(ROUGH_SAMPLES); i++) {
    vec3 noise  = blue_noise(floor(gl_FragCoord.xy), frameCounter, int(i));
    vec3 microFacit = clamp(
      SampleVNDFGGX(tangentView, vec2(roughness), noise.xy),
      0,
      1
    ); 

    vec3 tangentReflDir = reflect(-tangentView, microFacit);

    accumulated += normalize(tbn * tangentReflDir);
  }
  reflectedDir = normalize(accumulated / float(ROUGH_SAMPLES));

  #else
  reflectedDir = reflect(viewDir, normal);
  #endif
  float waterOrZeroMask2 = float(isWater || roughness <= 0);
  vec3 altReflectedDir = reflect(viewDir, normal);
  reflectedDir = mix(reflectedDir, altReflectedDir, waterOrZeroMask2);
  vec3 reflectedPos = vec3(0.0);
  vec3 reflectedColor = vec3(0.0);
 
 

  // --- Fresnel
  float NdotV = max(dot(normal, -viewDir), 0.0);
  vec3 F = fresnelSchlick(NdotV, f0);
 
  #ifdef DO_SSR
  // SSR raytrace
  bool noSky = lightmap.g < .955;
  vec3 noiseB = blue_noise(floor(gl_FragCoord.xy), frameCounter);
 bool reflectionHit = raytrace(
    viewPos,
    reflectedDir,
    SSR_STEPS,
    smoothLightmap,
    noiseB.x,
    reflectedPos
  );
  
  vec3 reflectedViewPos = screenSpaceToViewSpace(reflectedPos);
  vec3 reflectedFeetPlayer = (gbufferModelViewInverse *
    vec4(reflectedViewPos, 1.0)).xyz;
  vec3 reflectedEyePlayer = reflectedFeetPlayer - gbufferModelViewInverse[3].xyz;
  vec3 prevReflView = (gbufferPreviousModelView * vec4(reflectedFeetPlayer, 1.0)).xyz;
  vec4 prevReflClip = gbufferPreviousProjection * vec4(prevReflView, 1.0);
  vec3 previousReflPos = (prevReflClip.xyz / prevReflClip.w) * 0.5 + 0.5;
  float fadeFactor = 1.0 - smoothstep(0.9, 1.0, max(abs(reflectedPos.x - 0.5),abs(reflectedPos.y - 0.5)) * 2);
  float reflDist = distance(reflectedViewPos,viewPos);

  float lod =  3.62 * (1.0 - exp(-9.0 - sqrt(roughness)));
  float lodOverride = float(roughness <= 0.0 || isWater);
  lod = mix(lod, 0.0, lodOverride);

    vec3 sky = skyFallbackBlend(
      reflectedDir,
      vec3(1.0, 0.898, 0.698),
      viewPos,
      texcoord,
      normal,
      roughness,
      isWater
    ) ;
    sky = mix(albedo,sky, smoothLightmap);
   float roughMask = step(0.0, roughness);
   sky *= mix(1.0, max(exp(6.32 * (0.301 - roughness)), 0.0), roughMask * float(!isWater));
   
    if (reflectionHit) {
    if (canReflect || isMetal || isWater) {

      #ifdef ROUGH_REFLECTION
      #if SSR_MIP_BLUR == 1
      reflectedColor = texture2DLod(colortex0, reflectedPos.xy, lod).rgb;
      #else
      reflectedColor = texture2DLod(colortex0, reflectedPos.xy, 0).rgb;
      #endif //MIP_BLUR
      #else
      reflectedColor = texture2DLod(colortex0, reflectedPos.xy, 0).rgb;
      #endif //ROUGH_REFLECTION
      
      // bilateral filter for denoising
    
         
      if (any(isnan(reflectedColor))) reflectedColor = vec3(0.0);
      float roughMask2 = step(0.0, roughness);
      reflectedColor *= mix(1.0, max(exp(12.02 * (0.061 - roughness)), 0.0), roughMask2);
      
    }
  }

  if (!reflectionHit && canReflect) {
  
       reflectedColor =sky;
  
  }

  reflectedColor *= F;

  

  vec3 wetReflectedColor = mix(color.rgb, reflectedColor  , rainFactor);
  reflectedColor = mix(reflectedColor, wetReflectedColor, rainFactor);
  
       // --- temporal reprojection for reflections --------------------------------
  #ifdef REFLECTION_FILTER
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
      depth = screenSpaceToViewSpace(depth);
      vec4 historyColor = texture(colortex14, prevCoord);
       currentPreviousView.z = screenSpaceToViewSpace(historyColor.a);
      // rejection checks
      bool historyRejection = clamp(prevCoord, 0, 1) != prevCoord;
     historyRejection || distance(previousView, currentPreviousView) > 0.1;
      float prevDepth = texture(depthtex0, prevCoord).r;

       float sampleNDCDepth = depth * 2.0 - 1.0;
        float sampleViewDepth = gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * sampleNDCDepth + gbufferProjectionInverse[3].w);
      float prevViewZ = projectAndDivide(gbufferProjectionInverse, vec3(prevCoord, prevDepth) * 2.0 - 1.0).z;
      float depthDelta = abs(depth - prevViewZ);
      float depthThreshold = max(0.01, abs(depth) * 0.01);
      float depthConfidence = pow(clamp(1.0 - depthDelta / depthThreshold, 0, 1), 2.0);
      float response = pow(roughness, 2.0) * reflDist;
      float reflLum = luminance(reflectedColor);
      
      float factor = 0.55;
      #ifndef ROUGH_REFLECTION
      factor = 0.0;
      #endif
      //factor = max(factor, clamp(reflLum, 0, 1) * factor);
      if(roughness < 0.05) factor = 0.35;
      bool rejectHistory = false;
        if(depthCheck <= 0.56 )rejectHistory = true; 
         if(prevDepth <= 0.56 )rejectHistory = true;
      
      float historyWeight = factor * float(!historyRejection) * float(!rejectHistory) * depthConfidence  ;
      
      reflectedColor = mix(reflectedColor, historyColor.rgb, historyWeight);
      if (any(isnan(reflectedColor))) reflectedColor = vec3(0.0);
        
  }
  history.rgb = reflectedColor;
  #endif
  reflectedColor *= karisAverage(reflectedColor);


  
 
  color.rgb += reflectedColor;

  #else

 
  vec3 fb = skyFallbackBlend(reflectedDir,  vec3(1.0, 0.898, 0.698), viewPos, texcoord, normal, roughness, isWater);
   
  if (canReflect && !inWater) {
    reflectedColor = fb;
     float smoothLightmap = smoothstep(0.882, 1.0, lightmap.g);
    reflectedColor = mix(color.rgb, reflectedColor, smoothLightmap);
    float roughMask3 = step(0.0, roughness);
    reflectedColor *= mix(1.0, max(exp(5.02 * (0.031 - roughness)), 0.0), roughMask3);
  }
   
  reflectedColor *= F;

   if(isMetal)
    {
      color.rgb += reflectedColor;
    }
    color.rgb += reflectedColor;
  #endif // DO_SSR

 

  // write reflection history buffer (colortex14) for next frame


}