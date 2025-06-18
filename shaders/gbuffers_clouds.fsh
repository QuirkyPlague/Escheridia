#version 330 compatibility

#include "/lib/uniforms.glsl"
uniform sampler2D gtexture;

#include "/lib/util.glsl"
#include "/lib/atmosphere/skyColor.glsl"
#include "/lib/blockID.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
in vec3 viewPos;
in vec3 feetPlayerPos;
/* RENDERTARGETS: 0,10 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 reflCloud;
void main() {
	color.a =0.1;
	color = texture(gtexture, texcoord) * glcolor ;
	reflCloud = texture(gtexture, texcoord) * glcolor;
	
	vec3 LightVector=normalize(shadowLightPosition);
	vec3 worldLightVector=mat3(gbufferModelViewInverse)*LightVector;
	reflCloud *= cloudScatter(reflCloud, worldLightVector, feetPlayerPos, viewPos);
	
}