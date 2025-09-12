#version 400 compatibility

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0,8,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 sunTex;
layout(location = 2) out vec4 godraySample;
void main() {
  color = texture(gtexture, texcoord) * glcolor;
  sunTex = texture(gtexture, texcoord) * glcolor * 0.8;
  if (color.a < alphaTestRef) {
    discard;
  }

}
