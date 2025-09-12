#version 400 compatibility

out vec2 texcoord;
out vec4 glcolor;
out vec3 viewPos;
void main() {
  gl_Position = ftransform();
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  glcolor = gl_Color;
  viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
}
