#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/FXAA.glsl"
#include "/lib/bloom.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  #if BLOOM_GLSL == 1
  vec4 SpecMap = texture(colortex5, texcoord);
  bool isMetal = SpecMap.g >= 230.0 / 255.0;
  float depth = texture(depthtex0, texcoord).r;
  color.rgb = computeBloomMix(texcoord, depth, isMetal);
  #endif

}
