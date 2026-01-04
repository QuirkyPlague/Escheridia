#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/bloom.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 bloomColor;

void main() {
  #if BLOOM_GLSL == 1

  vec2 OriginCoord = vec2(0.0);
  float coordScalar = 0.5;
  vec2 screenCoord = (texcoord - OriginCoord) / coordScalar;
  if (clamp(screenCoord, 0, 1) != screenCoord) {
    bloomColor = vec4(0.0); // write black to remove whatever from the buffer
    return;
  }
  bloomColor.rgb = downsampleScreen(colortex0, screenCoord, true);

  #endif
}
