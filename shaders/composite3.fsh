#version 330 compatibility

#include "/lib/util.glsl"

#include "lib/atmosphere/godrays.glsl"

in vec2 texcoord;
vec3 geoNormal = texture(colortex10, texcoord).rgb;

/* RENDERTARGETS: 7 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
    vec3 geometryNormal = normalize((geoNormal - 0.5) * 2.0); // we normalize to make sure it is out of unit length
  //shadows
  #if GODRAYS_ENABLE ==1
	color.rgb = sampleGodrays(color.rgb, texcoord);
	#endif
	 
}