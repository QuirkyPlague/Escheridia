#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex0, texcoord).r;
  vec2 lightmap = texture(colortex1, texcoord).rg;
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec4 SpecMap = texture(colortex5, texcoord);

  bool isMetal = SpecMap.g >= 230.0 / 255.0;
  if (depth == 1) return;
  if (inWater) {
    depth = texture(depthtex1, texcoord).r;
  }

  if (!inWater) {
    vec3 distanceFog = distanceFog(color.rgb, viewPos, texcoord, depth);
    vec3 distanceMieFog = distanceMie(color.rgb, viewPos, texcoord, depth);
    vec3 fullFog = mix(distanceFog, distanceMieFog, 0.5);
    color.rgb = mix(color.rgb, fullFog, 1.0);
  }
  vec4 waterMask = texture(colortex4, texcoord);

  float depth1 = texture(depthtex1, texcoord).r;

  int blockID = int(waterMask) + 100;

  bool isWater = blockID == WATER_ID;

  if (isWater && !inWater && isMetal) {
    color.rgb = waterExtinction(color.rgb, texcoord, lightmap, depth, depth1);
  }
  if (inWater && isMetal) {
    vec3 waterScatter = waterFog(color.rgb, texcoord, lightmap, depth);
    color.rgb = waterScatter;
  }
}

