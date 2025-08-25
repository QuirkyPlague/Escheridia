#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  vec4 SpecMap = texture(colortex5, texcoord);

  bool isMetal = SpecMap.g >= 230.0 / 255.0;
  #if VOLUMETRIC_LIGHTING == 1 || VOLUMETRIC_LIGHTING == 2
  color.rgb += texture(colortex3, texcoord).rgb;
  #endif

}
