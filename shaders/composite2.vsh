#version 410 compatibility



out vec2 texcoord;
out vec3 normal;
uniform mat4 gbufferModelViewInverse;


void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	normal = gl_NormalMatrix * gl_Normal;
	normal = mat3(gbufferModelViewInverse) * normal;
}