#version 420 compatibility

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0,8 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 sunTex;
void main() {
	color = texture(gtexture, texcoord) * glcolor;
	sunTex = texture(gtexture, texcoord) * glcolor;
	if (color.a < alphaTestRef) {
		discard;
	}
	
}