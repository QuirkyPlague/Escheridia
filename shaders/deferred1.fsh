#version 400 compatibility

#include "/lib/lighting/lighting.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/postProcessing.glsl"
#include "/lib/blockID.glsl"
#include "/lib/tonemapping.glsl"
#include "/lib/water/waves.glsl"
#include "/lib/shadows/SSAO.glsl"
#include "/lib/lighting/sphericalHarmonics.glsl"

in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  
  // Check sky early before expensive texture reads
  float depth = texture(depthtex1, texcoord).r;
  if (depth == 1) return; //return out of function to prevent lighting interating with sky

  //assign colortex buffers
  color = texture(colortex0, texcoord);
    color = pow(color, vec4(2.2));
  vec3 albedo = color.rgb;
  
  vec2 lightmap = texture(colortex1, texcoord).rg;
  vec4 SpecMap = texture(colortex3, texcoord);
  vec4 normalData = texture(colortex2, texcoord);
  vec3 encodedNormal = normalData.rgb;
  float ao = normalData.a;
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
  vec3 surfNorm = texture(colortex4, texcoord).rgb;
  vec3 geoNormal = normalize((surfNorm - 0.5) * 2.0);
 
  vec4 mask = texture(colortex7, texcoord);
  int blockID = int(mask) + 103;

  //space conversions
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 worldPos = cameraPosition + feetPlayerPos;
  vec3 viewDir = normalize(viewPos);
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
   
  

  vec3 V = normalize(-feetPlayerPos);
  vec3 L = worldLightVector;
  vec3 H = normalize(V + L);
  float VdotL = dot(normalize(feetPlayerPos), worldLightVector);

  vec2 noisePos = fract(worldPos.xz /128.0);
  float puddleNoise = texture(puddleTex, noisePos).r;
  float noise = puddleNoise;
  noise *= wetness;
  noise *= clamp(dot(geoNormal, gbufferModelView[1].xyz),0,1);
  bool isMetal = SpecMap.g >= 230.0 / 255.0;
  bool canScatter = blockID == SSS_ID;
  const float handDepth = MC_HAND_DEPTH * 0.5 + 0.5;
  float flatness = max(dot(normalize(geoNormal), vec3(0.0, 1.0, 0.0)), 0.0);

  // Use cached puddle noise instead of reading again
  float rainFactor = 0.0;
  float isNotHand = step(handDepth, depth);
  rainFactor = isNotHand *
    clamp(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y),0,1) * wetness *
    smoothstep(-0.45, 0.75, puddleNoise) * flatness * snowBiomeSmooth * hotBiomeSmooth;
  
  //PBR
  float roughness = pow(1.0 - SpecMap.r, 2.0);
  float sss = 0.0;
  vec3 greyAlbedo = clamp(CSB(albedo, 1.0, 0.0, 2.115), 0.0, 1.0);

  #ifdef HC_SSS
  if (canScatter) {
    greyAlbedo = clamp(CSB(albedo, 1.0, 0.0, 0.4), 0.0, 1.0);
    sss = clamp(max(luminance(greyAlbedo), float(greyAlbedo)), 0, 1);
  } else {
    sss = 0.0;
  }
  #else
  sss = SpecMap.b;
  #endif

   float porosity = 0.0;
   #ifndef HC_SSS
   float isLow = step(SpecMap.b, 64.0/255.0);
   porosity = isLow * SpecMap.b * 6.0;
   sss = (1.0 - isLow) * ((SpecMap.b - 0.15) * 4.0 / 3.0);
#endif

  
  float emission = SpecMap.a;
  vec3 emissive = vec3(0.0);
  #ifndef HC_EMISSION
  if (emission < 1.0) {
    emission = min(emission, 0.95);
    emissive += color.rgb * emission;
    emissive += max(32.25 * pow(emissive, vec3(1.78)), 0.0);
    emissive = CSB(emissive, 1.0, 0.95, 1.0);
  }
#endif //HC_EMISSION

  vec3 shadow = getSoftShadow(shadowClipPos, geoNormal, sss);
  
  vec3 f0 = mix(vec3(SpecMap.g), albedo, float(isMetal));
  f0 = mix(f0, vec3(0.04), step(SpecMap.g, 0.0));
  float ambientOcclusion = 1.0;
  #if AO_METHOD == 1
   ambientOcclusion = texture(colortex12, texcoord).r;
  #endif
  roughness = mix(roughness,roughness *0.083, noise * (1.0 - porosity) * 0.8);
  color.rgb *= 1.0 - 0.5 * noise * porosity;

  vec3 blocklight = texture(colortex9, texcoord).rgb;
  vec3 SH = computeSkylight(normal);

  color.rgb =
    getLighting(
      color.rgb,
      lightmap,
      normal,
      shadow,
      H,
      f0,
      roughness,
      V,
      ambientOcclusion,
      sss,
      VdotL,
      isMetal,
      ao,
      geoNormal,
      blocklight,
      SH
    ) +
    emissive;


    
}
