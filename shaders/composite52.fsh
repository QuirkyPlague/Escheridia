#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/FXAA.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  #if FXAA_GLSL == 1
  color.rgb = FXAA(texture(colortex0, texcoord).rgb, colortex0, texcoord);
  #endif

}
