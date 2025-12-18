#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/blockID.glsl"

in vec4 at_tangent;
out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out mat3 tbnMatrix;
out vec3 modelPos;
out vec3 viewPos;
out vec3 feetPlayerPos;
flat out int blockID;
in vec4 at_midBlock;
out float emission;
in vec2 mc_Entity;

void main() {
  gl_Position = ftransform();
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  lmcoord = (lmcoord - 1.0 / 32.0) * 32.0 / 30.0;
  glcolor = gl_Color;

  normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
  normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space

  const float inf = uintBitsToFloat(0x7f800000u);
  float handedness = clamp(at_tangent.w * inf, -1.0, 1.0); // -1.0 when at_tangent.w is negative, and 1.0 when it's positive

  vec3 tangent =
    mat3(gbufferModelViewInverse) * normalize(gl_NormalMatrix * at_tangent.xyz);
  vec3 binormal = normalize(cross(tangent, normal) * handedness);
  tbnMatrix = mat3(tangent, binormal, normal);

  modelPos = gl_Vertex.xyz;
  viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
  feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

  blockID = int(mc_Entity.x + 0.5);
  emission = at_midBlock.w / 15.0;

}

