#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/brdf.glsl"
#include "/lib/blockID.glsl"
#include "/lib/postProcessing.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex0, texcoord).r;
  if (depth == 1.0) {
    return;
  }
  //buffers
  vec4 SpecMap = texture(colortex5, texcoord);
  vec4 sssMask = texture(colortex11, texcoord);
  vec4 waterMask = texture(colortex4, texcoord);
  vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components
  vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
  vec3 baseNormal = texture(colortex6, texcoord).rgb;
  vec3 geoNormal = normalize((baseNormal - 0.5) * 2.0);
  vec3 albedo = texture(colortex0, texcoord).rgb;

  //id masks
  int blockID2 = int(waterMask) + 100;
  int blockID = int(sssMask) + 103;
  bool isMetal = SpecMap.g >= 230.0 / 255.0;

  //bools
  bool isWater = blockID2 == WATER_ID;
  bool canScatter = blockID == SSS_ID;

  //space conversions
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 worldPos = cameraPosition + feetPlayerPos;
  vec3 viewDir = normalize(viewPos);
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
  vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
  vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;

  //pbr
  float sss;
  float roughness;
  vec3 f0;
  vec3 greyAlbedo = clamp(CSB(albedo, 1.0, 0.0,2.115), 0.0, 1.0);
  #if RESOURCE_PACK_SUPPORT == 1
  if (canScatter) {
    greyAlbedo = clamp(CSB(albedo, 1.0, 0.0,0.3), 0.0, 1.0);
    sss = clamp(max(luminance(greyAlbedo), float(greyAlbedo * 1)),0,1);

  } else {
    sss = 0.0;
    if (!isWater) {
      roughness = min(luminance(greyAlbedo - 1.0), float(greyAlbedo));
      vec3 greyAlbedo2 = CSB(albedo, 0.45, 0.0,1.3);
      float albedoLum = luminance(greyAlbedo2);
      f0 = clamp(min(albedo *albedoLum, (albedo )),0,1);
    }

  }
  #elif RESOURCE_PACK_SUPPORT == 0
  sss = SpecMap.b;
  roughness = pow(1.0 - SpecMap.r, 2.0);
  #else
  sss = 0.0;
  roughness = 1.0;
  #endif

  float emission = SpecMap.a;
  vec3 emissive;

  
  if (emission < 255.0/255.0) {
    emissive += albedo * (emission);
    emissive += max(0.55 * pow(emissive, vec3(0.8)), 0.0);

     emissive += min(luminance(emissive * 6.05) * pow(emissive, vec3(1.25)),33.15 ) ;
    emissive = CSB(emissive, 1.0 * EMISSIVE_MULTIPLIER, EMISSIVE_DESATURATION , 1.0);
  }
vec3 noise =  blue_noise(gl_FragCoord.xy,  frameCounter, SHADOW_SAMPLES);
  vec3 shadow = getSoftShadow(feetPlayerPos, geoNormal, sss, noise.x);

  vec3 V = normalize(cameraPosition - worldPos);
  vec3 L = normalize(worldLightVector);
  vec3 H = normalize(V + L);

  float ao = encodedNormal.z * 0.5 + 0.5;
  vec3 diffuse = doDiffuse(
    texcoord,
    lightmap,
    normal,
    worldLightVector,
    shadow,
    viewPos,
    sss,
    feetPlayerPos,
    isMetal,
    shadowScreenPos,
    albedo,
    ao
  );
  vec3 sunlight;
  vec3 currentSunlight = currentSunColor(sunlight);
  vec3 specular = brdf(
    albedo,
    f0,
    L,
    currentSunlight,
    normal,
    H,
    V,
    roughness,
    SpecMap,
    diffuse,
    shadow
  );

  vec3 lighting;

  #if RESOURCE_PACK_SUPPORT == 0
  if (!isMetal) {
    lighting = specular + emissive;
  } else {
    lighting = specular + emissive;
  }
  #else

  lighting = specular;
  #endif

  #if LIGHTING_GLSL == 1
  color.rgb = lighting;
  #endif

}
