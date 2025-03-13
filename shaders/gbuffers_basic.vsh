#version 410 compatibility

#include "/lib/util.glsl"
in vec4 at_tangent;
out vec2 lmcoord;
flat out int blockID;
in vec4 at_midBlock;
in vec2 mc_midTexCoord;

out vec2 texcoord;
out vec4 glcolor;
in vec2 mc_Entity;
out vec3 normal;
out float emission;
out mat3 tbnMatrix;

void main() {
	gl_Position = ftransform();
	glcolor = gl_Color;

}