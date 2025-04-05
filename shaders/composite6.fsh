#version 410 compatibility

#include "/lib/util.glsl"
#include "/lib/bloom.glsl"

in vec2 texcoord;
/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 color;


void main() {
   // color = vec4(upSample(colortex5, texcoord), 1.0);
}