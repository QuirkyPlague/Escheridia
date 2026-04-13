#version 430 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/postProcessing.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  #ifdef DO_CHROMATIC_ABERRATION
  color.rgb = chromaticAberration(texcoord, colortex0);
  #endif
  
}
