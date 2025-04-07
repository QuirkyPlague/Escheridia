#version 410 compatibility

#include "/lib/uniforms.glsl"
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
/* RENDERTARGETS: 0,1,2,7 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 godraySample;

void main() {
	color = texture(gtexture, texcoord) * glcolor;

	if (color.a < alphaTestRef) {
		discard;
	}
	color.rgb = pow(color.rgb, vec3(2.2));
	godraySample = color;
	
}