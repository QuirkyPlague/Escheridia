#version 410 compatibility
#include "/lib/util.glsl"


in vec2 texcoord;
const float bloomRadius = BLOOM_THRESHOLD;

/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	 
     //depth calculation
	float depth = texture(depthtex0, texcoord).r;
			if(depth >= 1.0)
			{
				return;
			}

	 #if DO_BLOOM == 1
     float brightness = dot(color.rgb, vec3(0.2157, 0.7216, 0.1294));;
    if(brightness >= 0.0)
        color = vec4(color.rgb, 1.0);
    else
        color = vec4(0.0, 0.0, 0.0, 1.0);
	#endif

	
}