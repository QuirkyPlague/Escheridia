#version 420 compatibility

#include "/lib/util.glsl"

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 viewPos;



void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = (lmcoord * 33.05 / 32.0) - (1.05 / 32.0);
	normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
	normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space
	glcolor = gl_Color;
	viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
  	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  	feetPlayerPos.xz += feetPlayerPos.y * -0.45;
  	viewPos = (gbufferModelView * vec4(feetPlayerPos, 1.0)).xyz;

 	 gl_Position = gbufferProjection * vec4(viewPos, 1.0);
}