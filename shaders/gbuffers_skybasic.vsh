#version 420 compatibility

#include "/lib/uniforms.glsl"

out vec4 glcolor;
out vec2 texcoord;
out vec3 modelPos;
out vec3 viewPos;
out vec3 normal;

void main() {
	gl_Position = ftransform();
	glcolor = gl_Color;
	 texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	modelPos = gl_Vertex.xyz;
	viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	
	normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
  	normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space


}
