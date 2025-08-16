#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/blockID.glsl"
#include "/lib/SSR.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/water/waves.glsl"
#include "/lib/atmosphere/skyColor.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/water/waterFog.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 skyFallbackBlend(vec3 dir, vec3 sunColor, vec3 viewPos, vec2 uv, vec3 normal) {
   vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
   vec3 eyePlayerPos =  feetPlayerPos - gbufferModelViewInverse[3].xyz;
   normal = (gbufferModelViewInverse * vec4(normal, 1.0)).xyz;
   normal = normal - gbufferModelViewInverse[3].xyz;
   vec3 dir2 = reflect(eyePlayerPos, normal);
  vec3 mie = calcMieSky(
    dir,
    worldLightVector,
    sunColor,
    viewPos,
    uv
  );
  vec4 SpecMap = texture(colortex5, texcoord);
 
  bool isMetal = SpecMap.g >= 230.0 / 255.0;
  vec3 sky = newSky(dir2) * 0.5;
  vec3 sun = skyboxSun(lightVector, dir, sunColor) ; // keep sun *3 as in original
  sky += mie * 0.15;
  sky = sky + sun * 0.3;
  return sky;
}

void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex0, texcoord).r;
  if (depth == 1.0) return;

  vec4 SpecMap = texture(colortex5, texcoord);
  vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec2 lightmap = texture(colortex1, texcoord).rg;
  vec4 sssMask = texture(colortex11, texcoord);
  vec4 waterMask = texture(colortex4, texcoord);
  vec4 translucentMask = texture(colortex7, texcoord);

  vec3 albedo = color.rgb;

  int blockID = int(waterMask) + 100;

  bool isWater = blockID == WATER_ID;
  bool isMetal = SpecMap.g >= 230.0 / 255.0;

  //Space conversions
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

  float farPlane = far / 0.35;

  vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
  normal = mat3(gbufferModelView) * normal;

  #ifdef WAVES
  if (isWater) {
    float waveFalloff = length(feetPlayerPos) / farPlane;
    float waveIntensityRolloff = exp(
      19.0 * WAVE_INTENSITY * (0.04 - waveFalloff)
    );
    float waveIntensity = 0.35 * 0.66 * WAVE_INTENSITY * waveIntensityRolloff;
    float waveSoftness = 0.02 * WAVE_SOFTNESS;

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
  vec3 sunColor = currentSunColor(vec3(0.0));

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
  float roughness = isWater ? 0.0 : baseRoughness;

  bool canReflect = roughness < 0.25;

  // --- Reflection vectors
  vec3 reflectedDir = reflect(viewDir, normal);
  vec3 reflectedPos = vec3(0.0);
  vec3 reflectedColor = vec3(0.0);

  // --- Fresnel
  float NdotV = max(dot(normal, -viewDir), 0.0);
  vec3 F = fresnelSchlick(NdotV, f0);

  #ifdef DO_SSR
  // SSR raytrace
  float jitter = IGN(gl_FragCoord.xy, frameCounter * SSR_STEPS);
  bool reflectionHit = raytrace(
    viewPos,
    reflectedDir,
    SSR_STEPS,
    jitter,
    reflectedPos
  );

  // Wet roughness adjustment (non-metals, not water, not cold)
  if (!isMetal && !isWater && !isColdBiome) {
    float wetRoughness = roughness * 0.02;
    roughness = mix(roughness, wetRoughness, clamp(wetness, 0.0, 1.0));
  }

  vec3 reflectedViewPos = screenSpaceToViewSpace(reflectedPos);
  float reflectedDist = distance(viewPos, reflectedViewPos);

  float lod = min(4.15 * (1.0 -pow(roughness, 12.0)), reflectedDist * 2);
  if (roughness <= 0.0 || isWater) lod = 0.0;

  #ifdef ROUGH_REFLECTION
 
  float sampleRadius = roughness * 0.015 * distance(reflectedViewPos, viewPos);
  for (int i = 0; i < ROUGH_SAMPLES; i++) {
    float j = IGN(gl_FragCoord.xy, frameCounter * ROUGH_SAMPLES) * 0.3;
    vec2 offset = vogelDisc(i, ROUGH_SAMPLES, j) * sampleRadius;
    vec3 offsetReflectedPos = reflectedPos + vec3(offset, 0.0);
    reflectedPos = offsetReflectedPos;
  }
  #else
  lod = 0.0;
  #endif

 
  if (reflectionHit) {
    if (canReflect || isMetal || isWater) {
      reflectedColor = texture2DLod(colortex0, reflectedPos.xy, lod).rgb;
    }
  }

  
  if (!reflectionHit && canReflect && !inWater) {
   
    vec3 fb = skyFallbackBlend(reflectedDir, sunColor, viewPos, texcoord, normal);
    reflectedColor = fb;

    float smoothLightmap = smoothstep(0.882, 1.0, lightmap.g);
    reflectedColor = mix(color.rgb, reflectedColor, smoothLightmap);
  }

  if (!reflectionHit && inWater && isWater) {
    reflectedColor = color.rgb;
  }

  //Rain stuff
  if (
    roughness < 0.1 + wetness &&
    !isMetal &&
    SpecMap.r <= 155.0 / 255.0 &&
    !isWater &&
    !isColdBiome
  ) {
    reflectedColor = texture2DLod(colortex0, reflectedPos.xy, lod).rgb;

    if (!reflectionHit) {
      vec3 dirR = reflect(normalize(viewPos), normal);
      vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(dirR, 1.0)).xyz;
    vec3 eyePlayerPos =  feetPlayerPos - gbufferModelViewInverse[3].xyz;
      vec3 mieR =
        calcMieSky(dirR, worldLightVector, sunColor, viewPos, texcoord);
      vec3 skyR = newSky(eyePlayerPos) ;
      vec3 sunR = skyboxSun(lightVector, dirR, sunColor) ;
      skyR = mix(sunR, skyR, 0.5);
      vec3 fullR = mix(skyR, mieR, 0.5);
      reflectedColor = fullR;
    }

    float smoothLightmap2 = smoothstep(0.882, 1.0, lightmap.g);
    reflectedColor = mix(color.rgb, reflectedColor, smoothLightmap2);
  }

  // Apply Fresnel and accumulate only in SSR path (matches original)
  reflectedColor *= F;
  reflectedColor = min(reflectedColor, vec3(5.0)); // arbitrary threshold
  color.rgb += reflectedColor;

  #else // !DO_SSR

  // No SSR: use sky fallback if reflective and not underwater.
  if ((canReflect || isMetal || isWater) && !inWater) {
    vec3 reflDir = reflect(normalize(viewPos), normal);
    vec3 fb = skyFallbackBlend(reflDir, sunColor, viewPos, texcoord);
    vec3 mieOnly = calcMieSky(
      normalize(reflDir),
      worldLightVector,
      sunColor,
      viewPos,
      texcoord
    );
    vec3 skyOnly = cnewSky(reflDir);
    vec3 sunOnly = skyboxSun(lightVector, reflDir, sunColor) * 3.0;
    skyOnly = mix(sunOnly, skyOnly, 0.5);
    vec3 fullSky = mix(skyOnly, mieOnly, 0.1);

    reflectedColor = fullSky;
    reflectedColor *= smoothstep(0.815, 1.0, lightmap.g);
    reflectedColor *= F;

    color.rgb += reflectedColor;

  }

  #endif // DO_SSR
}
