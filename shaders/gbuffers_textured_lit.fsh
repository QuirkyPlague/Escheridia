#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/blockID.glsl"

uniform sampler2D gtexture;



in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
in vec3 viewPos;
flat in int blockID;
/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
void main() {
	
	color = texture(gtexture, texcoord) * glcolor  ;

	if(color.a < 0.1) discard;
	

	
	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);
	vec4 albedo  = texture(gtexture, texcoord) * glcolor  ;
	lightmapData = vec4(lmcoord, 0.0, 1.0);

	

}