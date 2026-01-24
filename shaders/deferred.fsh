#version 400 compatibility

#include "/lib/lighting/lighting.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/postProcessing.glsl"
#include "/lib/blockID.glsl"
#include "/lib/tonemapping.glsl"
#include "/lib/water/waves.glsl"
#include "/lib/shadows/SSAO.glsl"

in vec2 texcoord;

void GriAndEminShadowFix(
	inout vec3 WorldPos,
	vec3 FlatNormal,
	float transition
){
	transition = 1.0-transition; 
	transition *= transition*transition*transition*transition*transition*transition;
	float zoomLevel = mix(0.0, 0.5, transition);

	if(zoomLevel > 0.001 && isEyeInWater != 1) WorldPos = WorldPos - (	fract(WorldPos+cameraPosition - WorldPos*0.0001)*zoomLevel - zoomLevel*0.5);
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 prevBuffer;
void main() {
  //assign colortex buffers
  color = texture(colortex0, texcoord);
  vec3 albedo = color.rgb;
  albedo = pow(albedo, vec3(2.2));
  vec2 lightmap = texture(colortex1, texcoord).rg;
  vec4 SpecMap = texture(colortex3, texcoord);
  vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
  vec3 surfNorm = texture(colortex4, texcoord).rgb;
  vec3 geoNormal = normalize((surfNorm - 0.5) * 2.0);
  float depth = texture(depthtex1, texcoord).r;
  vec4 mask = texture(colortex7, texcoord);
  vec4 ao = texture(colortex9, texcoord);

  int blockID = int(mask) + 103;
  if (depth == 1) return; //return out of function to prevent lighting interating with sky

  //space conversions
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 worldPos = cameraPosition + feetPlayerPos;
  vec3 viewDir = normalize(viewPos);
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    float lightLeakFix = clamp(pow(eyeBrightnessSmooth.y/240. + lightmap.y,2.0) ,0.0,1.0);
  GriAndEminShadowFix(feetPlayerPos, geoNormal,lightLeakFix );
  vec3 V = normalize(-feetPlayerPos);
  vec3 L = worldLightVector;
  vec3 H = normalize(V + L);
  float VdotL = dot(normalize(feetPlayerPos), worldLightVector);

  vec2 noisePos = fract(worldPos.xz /128.0);
  float noise = texture(puddleTex, noisePos).r;
  noise *= wetness;
  noise *= clamp(dot(geoNormal, gbufferModelView[1].xyz),0,1);
  bool isMetal = SpecMap.g >= 230.0 / 255.0;
  bool canScatter = blockID == SSS_ID;
  const float handDepth = MC_HAND_DEPTH * 0.5 + 0.5;
  float flatness = max(dot(normalize(geoNormal), vec3(0.0, 1.0, 0.0)), 0.0);


  float rainFactor = 0.0;
    if(depth > handDepth )
    {
      
         rainFactor =
    clamp(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y),0,1) * wetness;
      rainFactor *= smoothstep(
    -0.55,
    0.65,
    texture(
      puddleTex,
      noisePos
    ).r
  ) * flatness * snowBiomeSmooth * hotBiomeSmooth;
    }
  
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
   if (SpecMap.b <= 64.0/255.0)
   {
    porosity = SpecMap.b * 6.0;
    sss = 0.0;
   }
   else
   {
    sss = (SpecMap.b - 0.15) * 4.0 / 3.0;
    porosity = 0.0;
   }
#endif

  
  float emission = SpecMap.a;
  vec3 emissive = vec3(0.0);
  #ifndef HC_EMISSION
  if (emission < 1.0) {
    emission = min(emission, 0.7);
    emissive += color.rgb * emission;
    emissive += max(21.25 * pow(emissive, vec3(2.08)), 0.0);
      
    emissive = CSB(emissive, 1.0, 0.85, 1.0);
    emissive = pow(emissive, vec3(2.2));
  }
#endif //HC_EMISSION

  vec3 shadow = getSoftShadow(shadowClipPos, geoNormal, sss);
  
  vec3 f0 = vec3(0.0);
  if (isMetal) {
    f0 = albedo;
  } else {
    f0 = vec3(SpecMap.g);
  }

  float ambientOcclusion = ssao(viewPos, normal);
  roughness = mix(roughness,roughness *0.013, noise * (1.0 - porosity) * 0.8);
  color.rgb *= 1.0 - 0.5 * noise * porosity;

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
      ao.a,
      sss,
      VdotL,
      isMetal,
      geoNormal
    ) +
    emissive;


    
}
