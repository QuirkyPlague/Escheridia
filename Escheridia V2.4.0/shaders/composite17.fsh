#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/bloom.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 bloomColor;

void main() {
  #if BLOOM_GLSL == 1
  vec2 OriginCoord = vec2(0.5 + 2 / (viewWidth * BLOOM_QUALITY), 0.0);
  bloomColor = vec4(0.0, 0.0, 0.0, 1.0);
  vec2 prevCoord = vec2(0.0);
  float coordScalar = 0.25;
  float prevScale = 0.5;
  vec2 screenCoord = (texcoord - prevCoord) / prevScale;
  bloomColor = texture(colortex12, texcoord);
  if (clamp(screenCoord, 0, 1) != screenCoord) {
    return;
  }
  screenCoord = screenCoord * coordScalar + OriginCoord;
  bloomColor.rgb += upSample(colortex12, screenCoord);
  #endif
}
