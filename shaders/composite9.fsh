#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/bloom.glsl" 

in vec2 texcoord;



/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 bloomColor;

void main() {
		#if BLOOM_GLSL ==1
		bloomColor = texture(colortex0, texcoord);
		
		bloomColor.rgb = vec3(0.0, 0.0, 0.0);
		vec2 OriginCoord = vec2(0.0);
		float coordScalar = 0.5;
		vec2 screenCoord = (texcoord - OriginCoord) / coordScalar;
		bloomColor.rgb = downsampleScreen(colortex0, screenCoord);

		#endif	
}