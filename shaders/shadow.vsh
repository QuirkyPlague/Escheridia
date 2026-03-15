#version 430 compatibility

layout (r32ui) uniform uimage3D voxelization;
layout (r32ui) uniform uimage3D voxelization1;

#include "/lib/shadows/distort.glsl"
#include "/lib/uniforms.glsl"
uniform sampler2D gtexture;
out vec2 texcoord;
out vec4 glcolor;
out vec3 feetPlayerPos;
out vec3 shadowViewPos;
in vec2 mc_Entity;

in vec4 at_midBlock;
uniform int entityId;
uniform int renderStage;


void main() {
  //standard stuff
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;

  shadowViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
  feetPlayerPos = (shadowModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;

  vec3 worldPos = feetPlayerPos + cameraPosition;


  #include "/voxels.glsl"

  gl_Position = gl_ProjectionMatrix * vec4(shadowViewPos, 1.0);
  gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
}
