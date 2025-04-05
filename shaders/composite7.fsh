#version 410 compatibility

#include "/lib/util.glsl"

in vec2 texcoord;
/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 color;


void main() {
vec3 bloom = texture(colortex5, texcoord).rgb;
//color.rgb = mix(color.rgb, bloom, clamp01(0.01 * BLOOM_STRENGTH * 0.1));
}