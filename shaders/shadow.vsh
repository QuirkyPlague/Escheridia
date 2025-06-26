#version 420 compatibility

#include "/lib/shadows/distort.glsl"
out vec2 texcoord;
out vec4 glcolor;

void main() {
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  glcolor = gl_Color;
  gl_Position = ftransform();
  gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
}