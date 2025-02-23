#version 410 compatibility

out vec2 lmcoord;
in vec2 mc_Entity;

out vec2 texcoord;
out vec4 glcolor;
flat out int blockID;

out vec3 normal;
uniform mat4 gbufferModelViewInverse;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = (lmcoord * 33.05 / 32.0) - (1.05 / 32.0);
	glcolor = gl_Color;
	normal = gl_NormalMatrix * gl_Normal;
	normal = mat3(gbufferModelViewInverse) * normal;

	blockID = int(mc_Entity.x * 0.5);

}