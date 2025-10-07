#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/bloom.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 bloomColor;

void main() {
  #if BLOOM_GLSL == 1

  vec2 OriginCoord = vec2(0.75 + 4 / (viewWidth * BLOOM_QUALITY), 0.0);
  vec2 prevCoord = vec2(0.5 + 2 / (viewWidth * BLOOM_QUALITY), 0.0);
  float coordScalar = 0.125;
  float prevScale = 0.25;
  vec2 screenCoord = (texcoord - OriginCoord) / coordScalar;
  if (clamp(screenCoord, 0, 1) != screenCoord) {
    bloomColor = texture(colortex12, texcoord); // write black to remove whatever from the buffer
    return;
  }
  screenCoord = screenCoord * prevScale + prevCoord;
  bloomColor.rgb = downsampleScreen(colortex12, screenCoord, false);

  #endif
}
