#version 410 compatibility

out vec2 texcoord;
out vec4 glcolor;

uniform mat4 gbufferProjectionInverse;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	  
glcolor = gl_Color;
	

	
}