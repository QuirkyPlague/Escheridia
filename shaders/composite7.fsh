#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blockID.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
color = texture(colortex0, texcoord);
     vec2 lightmap = texture(colortex1, texcoord).rg;
  float depth = texture(depthtex0, texcoord).r;
 #ifndef ADVANCED_FOG_TRACING
  if (depth == 1.0) return;
  #endif
  vec4 SpecMap = texture(colortex3, texcoord);
  bool isMetal = SpecMap.g >= 230.0 / 255.0;
   vec3 surfNorm = texture(colortex4, texcoord).rgb;
  vec3 geoNormal = normalize((surfNorm - 0.5) * 2.0);
  //space conversions
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
  vec3 worldPos = feetPlayerPos + cameraPosition;
  vec4 waterMask = texture(colortex5, texcoord);
  int blockID = int(waterMask) + 100;
  bool isWater = blockID == WATER_ID;
  vec3 noise;
  for(int i = 0; i < VL_ATMOSPHERIC_STEPS; i++)
  {
    noise = blue_noise(floor(gl_FragCoord.xy), frameCounter, i);
  }
  vec3 shadowViewPos_start = (shadowModelView * vec4(vec3(0.0), 1.0)).xyz;
  vec4 shadowClipPos_start = shadowProjection * vec4(shadowViewPos_start, 1.0);

  vec3 shadowViewPos_end = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos_end = shadowProjection * vec4(shadowViewPos_end, 1.0);

  vec3 startPos = shadowClipPos_start.xyz;
  vec3 endPos = shadowClipPos_end.xyz;
   vec3 fog;
  #ifdef ENVIORNMENT_FOG
   fog = atmosphericFog(color.rgb, viewPos, depth,texcoord, isWater);
  #ifdef ADVANCED_FOG_TRACING
   fog = VL_Atmospherics(startPos, endPos, feetPlayerPos, VL_ATMOSPHERIC_STEPS,color.rgb, worldPos,noise.x) + color.rgb;
  #endif
  #endif

   if(!inWater)
  {
    color.rgb = fog;
  }
  
}
