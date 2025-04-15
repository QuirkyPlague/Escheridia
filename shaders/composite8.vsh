#version 330 compatibility

#include "/lib/uniforms.glsl"

out vec2 texcoord;
out vec3 normal;



void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	normal = gl_NormalMatrix * gl_Normal;
	normal = mat3(gbufferModelViewInverse) * normal;
}