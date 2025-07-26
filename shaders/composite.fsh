#version 420 compatibility

uniform sampler2D colortex0;
in vec2 texcoord;



/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
    color.rgb = pow(color.rgb, vec3(2.2));

}