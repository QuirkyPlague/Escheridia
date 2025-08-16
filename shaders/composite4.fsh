#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

}
