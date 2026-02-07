#version 400 compatibility

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

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

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

    accumulated += skyCol;

  }
  vec3 sky = accumulated / float(ROUGH_SAMPLES);
  if (isWater || roughness <= 0) {
    dir2 = reflect(eyePlayerPos, normal);

    vec3 skyCol = skyScattering(normalize(dir2));
    vec3 sunCol = getSun(normalize(dir2));
    sky = sunCol + skyCol;

  }
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
  vec4 waterMask = texture(colortex5, texcoord);
  vec3 surfNorm = texture(colortex4, texcoord).rgb;
  vec3 geoNormal = normalize((surfNorm - 0.5) * 2.0);

  vec3 albedo = texture(colortex0, texcoord).rgb;
  
  int blockID = int(waterMask) + 100;

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

  float rainFactor = 0.0;
    if(depth > handDepth )
    {
      if(!isWater)
      {
         rainFactor =
    clamp(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y),0,1) * wetness;
      rainFactor *= smoothstep(
    -0.45,
    0.65,
    texture(
      puddleTex,
      noisePos
    ).r
  ) * flatness * snowBiomeSmooth * hotBiomeSmooth;
      }
    }

  
 float waveNoise =  texture(waterTex,mod((feetPlayerPos.xz + cameraPosition.xz) / 2.0, 128.0) / 128.0).r;
  #ifdef WAVES
  if (isWater) {
    if(flatness >= 1e-6)
    {
      float waveFalloff = length(feetPlayerPos) / farPlane;
    float waveIntensityRolloff = exp(
      3.0 * WAVE_INTENSITY * (0.05 - waveFalloff)
    );
    float waveIntensity = 0.177 * WAVE_INTENSITY * waveIntensityRolloff;
    float waveSoftness = 0.04 * WAVE_SOFTNESS;

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
    float waveIntensity = 0.137 * WAVE_INTENSITY * waveIntensityRolloff;
    float waveSoftness = 0.018 * WAVE_SOFTNESS;

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
    float waveIntensity = 0.045 * WAVE_INTENSITY  * rainFactor;
    float waveSoftness = 0.48 * WAVE_SOFTNESS;

    vec3 rainNormal = rainNormals(
      feetPlayerPos.xz + cameraPosition.xz,
      waveSoftness,
      waveIntensity, rainFactor
    );
    rainNormal = mat3(gbufferModelView) * rainNormal;
    
      normal = mix(normal, rainNormal, rainFactor);
  #else

  if (isWater) {
    normal = normal;
  }
  #endif

  // --- F0 and roughness
  vec3 f0;
  if (isMetal) {
    f0 = albedo *16;
  } else if (isWater) {
    f0 = vec3(0.02);
  } else {
    f0 = vec3(SpecMap.g);
  }
  if (inWater && isWater) {
    f0 = vec3(1.0);
  }
  
  
  f0 = mix(f0, vec3(0.02), rainFactor);
  float bRough = roughness;
  float wetRoughness = mix(roughness* 0.7, roughness * 0.0, rainFactor);
  

  roughness = mix(roughness,wetRoughness, wetness);
  
  bool canReflect = roughness < 1.0;
   vec3 noiseB = vec3(0.0);
   for(int i = 0; i < 3; i++) {
        noiseB += blue_noise(floor(gl_FragCoord.xy), frameCounter, i) ;
    }
  
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
  vec3 noise = vec3(0.0);
  for (uint i = 0u; i < uint(ROUGH_SAMPLES); i++) {
    noise  = blue_noise(floor(gl_FragCoord.xy), frameCounter, int(i));
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
  if (isWater || roughness <= 0) {
    reflectedDir = reflect(viewDir, normal);
  }
  vec3 reflectedPos = vec3(0.0);
  vec3 reflectedColor = vec3(0.0);
 
 

  // --- Fresnel
  float NdotV = max(dot(normal, -viewDir), 0.0);
  vec3 F = fresnelSchlick(NdotV, f0);
 
  #ifdef DO_SSR
  // SSR raytrace
  bool noSky = lightmap.g < .955;
 bool reflectionHit = raytrace(
    viewPos,
    reflectedDir,
    SSR_STEPS,
    noiseB.x,
    smoothLightmap,
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
  if (roughness <= 0.0 || isWater) lod = 0.0;

    vec3 sky = skyFallbackBlend(
      reflectedDir,
      vec3(1.0, 0.898, 0.698),
      viewPos,
      texcoord,
      normal,
      roughness,
      isWater
    ) ;
    
   if(roughness > 0)
   {
    sky *= max(exp(4.32 * (0.101 - roughness)), 0.0);
   }
   
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
      
      if (any(isnan(reflectedColor))) reflectedColor = vec3(0.0);
      if(roughness > 0)  reflectedColor *= max(exp(7.02 * (0.061 - roughness)), 0.0);
    
    }
  }

  if (!reflectionHit && canReflect && !inWater) {
  
       reflectedColor =sky;
    
      
      reflectedColor = mix(color.rgb, reflectedColor, smoothLightmap);
  }
  
  

  reflectedColor *= F;
  reflectedColor *= karisAverage(reflectedColor) ;
  reflectedColor *= karisAverage(reflectedColor) ;
  reflectedColor *= karisAverage(reflectedColor) ;

  vec3 wetReflectedColor = mix(color.rgb, reflectedColor  , rainFactor);
  reflectedColor = mix(reflectedColor, wetReflectedColor, rainFactor);
  
  if(isMetal)
  {
    color.rgb = reflectedColor;
  }
 
  color.rgb += reflectedColor;

  #else

 
  vec3 fb = skyFallbackBlend(reflectedDir,  vec3(1.0, 0.898, 0.698), viewPos, texcoord, normal, roughness, isWater);
   
  if (canReflect && !inWater) {
    reflectedColor = fb;
     float smoothLightmap = smoothstep(0.882, 1.0, lightmap.g);
    reflectedColor = mix(color.rgb, reflectedColor, smoothLightmap);
    if(roughness > 0)  reflectedColor *= max(exp(5.02 * (0.031 - roughness)), 0.0);
  }
   
  reflectedColor *= F;
   if(isMetal)
    {
      color.rgb += reflectedColor;
    }
    color.rgb += reflectedColor;
  #endif // DO_SSR

}