#version 410 compatibility

#include "/lib/util.glsl"

in vec2 texcoord;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;


void main() {
color = texture(colortex0, texcoord);
color.rgb += texture(colortex6, texcoord).rgb;

}