#version 410 compatibility

uniform sampler2D colortex0;
uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D depthtex1;
uniform sampler2D depthtex0;
uniform float alphaTestRef = 1.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	
	float depth = texture(depthtex0, texcoord).r;
			if(depth == 1.0)
			{
				return;
			}

	if (color.a < alphaTestRef) {
		discard;
	}
	color.rgb = pow(color.rgb, vec3(2.2));
}