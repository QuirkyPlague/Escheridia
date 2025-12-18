#version 400 compatibility

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec2 lmcoord;
/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 encodedNormal;

void main() {
  color = texture(gtexture, texcoord) * glcolor;
  if (color.a < alphaTestRef) {
    discard;
  }
  color.rgb = pow(color.rgb, vec3(2.2));

  color*= 2;

  encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);

}
