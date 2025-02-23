#version 410 compatibility

out vec4 glcolor;
out vec3 viewPos;
uniform vec3 sunPosition;
in vec2 lmcoord;
in vec2 texcoord;

in vec3 normal;
uniform mat3 gbufferModelViewInverse;

void main() {
	gl_Position = ftransform();
	glcolor = gl_Color;
	
}
