#version 410 compatibility

#include "/lib/util.glsl"
in vec4 at_tangent;
out vec2 lmcoord;
flat out int blockID;

out vec2 texcoord;
out vec4 glcolor;
in vec2 mc_Entity;
out vec3 normal;

out mat3 tbnMatrix;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = (lmcoord * 33.05 / 32.0) - (1.05 / 32.0);
	glcolor = gl_Color;
	normal = gl_NormalMatrix * gl_Normal;
	normal = mat3(gbufferModelViewInverse) * normal;
	
	vec3 tangent = mat3(gbufferModelViewInverse) * normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = mat3(gbufferModelViewInverse) * normalize(cross(tangent, normal) * at_tangent.w);
	tbnMatrix = mat3(tangent, binormal, normal);
	
	blockID = int(mc_Entity.x + 0.5);
}