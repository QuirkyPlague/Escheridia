#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/blockID.glsl"
#include "/lib/SSR.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/water/waves.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/water/waterFog.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

mat3 tbnMatrix(vec3 N)
{
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
          vec3 noise =  blue_noise(floor(gl_FragCoord.xy), frameCounter, int(i));
        vec3 microFacit = SampleVNDFGGX(tangentView, vec2(roughness), noise.xy);

        vec3 tangentReflDir = reflect(-tangentView, microFacit);

        
         vec3 skyDir = normalize(tbn * tangentReflDir);
        
        vec3 skyCol = skyScattering(skyDir);
        vec3 sunCol = getSun(skyDir);
        
        accumulated += (skyCol + sunCol);
        
    }
    vec3 sky = accumulated / float(ROUGH_SAMPLES);
    if(isWater || roughness <= 0)
    {
      dir2 = reflect(eyePlayerPos, normal);
   
        vec3 skyCol = skyScattering(normalize(dir2));
        vec3 sunCol = getSun(normalize(dir2));
         sky = (sunCol + skyCol) ;
         
    }
  #else
  dir2 = reflect(normalize(eyePlayerPos), normal);
   
        vec3 skyCol = skyScattering(dir2);
        vec3 sunCol = getSun(dir2);
        vec3 sky = sunCol + skyCol;
  #endif

sky = pow(sky, vec3(2.2));
  return sky* 0.85;
}



void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex0, texcoord).r;
  if (depth == 1.0) return;

  vec4 SpecMap = texture(colortex3, texcoord);
  vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec2 lightmap = texture(colortex1, texcoord).rg;
  vec4 waterMask = texture(colortex5, texcoord);


  vec3 albedo = color.rgb;

  int blockID = int(waterMask) + 100;

  bool isWater = blockID == WATER_ID;
  bool isMetal = SpecMap.g >= 230.0 / 255.0;

  //Space conversions
  vec3 screenPos = vec3(texcoord.xy, depth);
  vec3 NDCPos = vec3(texcoord, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 viewDir = normalize(viewPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

  #if PIXELATED_LIGHTING == 1
  feetPlayerPos += cameraPosition;
  feetPlayerPos = floor(feetPlayerPos * 16.0 + 0.01) / 16.0;
  feetPlayerPos -= cameraPosition;
  viewPos = (gbufferModelView * vec4(feetPlayerPos, 1.0)).xyz;
  #endif

  float farPlane = far / 0.45;

  vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
  normal = mat3(gbufferModelView) * normal;

  #ifdef WAVES
  if (isWater) {
    float waveFalloff = length(feetPlayerPos) / farPlane;
    float waveIntensityRolloff = exp(
      30.0 * WAVE_INTENSITY * (0.005 - waveFalloff)
    );
    float waveIntensity = 0.1 * WAVE_INTENSITY * waveIntensityRolloff;
    float waveSoftness = 0.008 * WAVE_SOFTNESS;

    normal = waveNormal(
      feetPlayerPos.xz + cameraPosition.xz,
      waveSoftness,
      waveIntensity
    );
    normal = mat3(gbufferModelView) * normal;
  }
  #else
  // keep branch to preserve exact original behavior for water path
  if (isWater) {
    normal = normal;
  }
  #endif

  // --- Sun color (compute once)
 

  // --- F0 and roughness
  vec3 f0;
  if (isMetal) {
    f0 = albedo;
  } else if (isWater) {
    f0 = vec3(0.02);
  } else {
    f0 = vec3(SpecMap.g);
  }
  if (inWater && isWater) {
    f0 = vec3(1.0);
  }

  float baseRoughness = pow(1.0 - SpecMap.r, 2.0);
  float roughness = isWater ? 0.000 : baseRoughness;

  bool canReflect = roughness < 0.3;
vec3 noiseB =  blue_noise(floor(gl_FragCoord.xy), frameCounter, SSR_STEPS);
vec2 offset;
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
        vec3 noise =  blue_noise(floor(gl_FragCoord.xy), frameCounter, int(i));
        vec3 microFacit = clamp(SampleVNDFGGX(tangentView, vec2(roughness), noise.xz), 0, 1);

          
        vec3 tangentReflDir = reflect(-tangentView, microFacit) ;

        
        accumulated += normalize(tbn * tangentReflDir)  ;
    }
    reflectedDir = normalize(accumulated / float(ROUGH_SAMPLES));
    
    
  #else
   reflectedDir = reflect(viewDir, normal);
  #endif
  if(isWater || roughness <= 0)
  {
    reflectedDir = reflect(viewDir, normal);
  }
  vec3 reflectedPos = vec3(0.0);
  vec3 reflectedColor = vec3(0.0);

  // --- Fresnel
  float NdotV = max(dot(normal, -viewDir), 0.0);
  vec3 F = fresnelSchlick(NdotV, f0);

  #ifdef DO_SSR
  // SSR raytrace

  vec3 ssrPos = rayTraceScene(screenPos, viewPos, reflectedDir, noiseB.y);
  

  vec3 reflectedViewPos = screenSpaceToViewSpace(ssrPos);
  vec3 reflectedFeetPlayer = (gbufferModelViewInverse * vec4(reflectedViewPos, 1.0)).xyz;
  reflectedFeetPlayer += cameraPosition;
  float reflectedDist = distance(cameraPosition, reflectedFeetPlayer);


  float lod = min(4.15 * (1.0 - pow(roughness, 12.0)), reflectedDist);
  if (roughness <= 0.0 || isWater) lod = 0.0;

   #ifdef ROUGH_REFLECTION

    const float MAX_RADIUS = 3.15;
      float alpha = roughness * 2.25e-4;
    float sampleRadius = mix(0.0, MAX_RADIUS, alpha) * reflectedDist;
    for (int i = 0; i < ROUGH_SAMPLES; i++) {
       vec3 noise =  blue_noise(floor(gl_FragCoord.xy), frameCounter, int(i));
    vec2 offset = vogelDisc(i, ROUGH_SAMPLES, noise.z) * sampleRadius;
    vec3 offsetReflection = ssrPos + vec3(offset, 0.0); // add offset
    ssrPos = offsetReflection;
    }
  #else
  lod = 0.0;
  #endif


if ((canReflect || isMetal || isWater)) {
  float smoothLightmap = smoothstep(0.882, 1.0, lightmap.g);
  vec3 sky = skyFallbackBlend(reflectedDir, vec3(1.0, 0.898, 0.698), viewPos, texcoord, normal, roughness, isWater);
 
  
  bool skyThreshold = canReflect;
  vec3 skyRefl =  skyThreshold ? mix(color.rgb, sky, smoothLightmap): color.rgb;
  reflectedColor  = ssrPos.z < 0.5 ? skyRefl  : texelFetch(colortex0, ivec2(ssrPos.xy), int(0)).rgb;
}
else if((canReflect || isMetal || isWater) && inWater)
{
  reflectedColor  = ssrPos.z < 0.5 ? color.rgb  : texelFetch(colortex0, ivec2(ssrPos.xy), int(0)).rgb;
}

  // Apply Fresnel and accumulate only in SSR path (matches original)
  reflectedColor *= F;
  reflectedColor = min(reflectedColor, vec3(16.0)); // arbitrary threshold
  color.rgb += reflectedColor;

  #else // !DO_SSR

  // No SSR: use sky fallback if reflective and not underwater.
  if ((canReflect || isMetal || isWater) && !inWater) {
    vec3 reflDir = reflect(normalize(viewPos), normal);
    vec3 fb = skyFallbackBlend(reflDir, sunColor, viewPos, texcoord, normal);
  
    reflectedColor = fb;
    reflectedColor *= smoothstep(0.815, 1.0, lightmap.g);
    reflectedColor *= F;

    color.rgb += reflectedColor;

  }

  #endif // DO_SSR
}
