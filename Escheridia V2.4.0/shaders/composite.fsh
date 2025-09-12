#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/util.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/atmosphere/volumetrics.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 3 */
layout(location = 0) out vec4 color;

void main() {
  float depth = texture(depthtex0, texcoord).r;
  float depth1 = texture(depthtex1, texcoord).r;

  //space conversions
  vec3 screenPos = vec3(texcoord.xy, depth);
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec4 waterMask = texture(colortex4, texcoord);
  int blockID = int(waterMask) + 100;
  bool isWater = blockID == WATER_ID;
  float jitter = IGN(gl_FragCoord.xy, frameCounter);
  int stepCount = GODRAYS_SAMPLES;

  #if VOLUMETRIC_LIGHTING == 1
  color.rgb = sampleGodrays(color.rgb, texcoord, feetPlayerPos, depth);

  #elif VOLUMETRIC_LIGHTING == 2

  
  vec3 shadowViewPos_start = (shadowModelView * vec4(vec3(0.0), 1.0)).xyz;
  vec4 shadowClipPos_start = shadowProjection * vec4(shadowViewPos_start, 1.0);


  vec3 shadowViewPos_end = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos_end = shadowProjection * vec4(shadowViewPos_end, 1.0);

  color.rgb = volumetricRaymarch(
    shadowClipPos_start,
    shadowClipPos_end,
    GODRAYS_SAMPLES,
    jitter,
    feetPlayerPos,
    color.rgb
  );

  #endif

}

