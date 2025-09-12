#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  #if VOLUMETRIC_LIGHTING == 1 || VOLUMETRIC_LIGHTING == 2
  #ifdef DO_SSR
  color.rgb += texture(colortex3, texcoord).rgb * 0.15;
  #endif
  #endif
}
