#version 420 compatibility

#include "/lib/uniforms.glsl"
uniform sampler2D gtexture;



in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;

void main() {
	color.a = 1.0;
	color = texture(gtexture, texcoord) * glcolor *color.a;
	color *= vec4(1.0, 1.0, 1.0, 0.434);
	if (color.a < 0.1) {
		discard;
	}

	

	
	
	
}