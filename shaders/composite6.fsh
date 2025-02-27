#version 410 compatibility

#include "/lib/util.glsl"


uniform bool horizontal;
uniform float weight[5] = float[] (0.227027 / BLOOM_STRENGTH, 0.1945946/ BLOOM_STRENGTH, 0.1216216 /BLOOM_STRENGTH , 0.054054 /BLOOM_STRENGTH , 0.016216 /BLOOM_STRENGTH);
in vec2 texcoord;


/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 color;


void main() {
	  #if DO_BLOOM == 1
     
     vec2 tex_offset =  BLOOM_VARIATIONS  / textureSize(colortex5, 0); // gets size of single texel
    vec3 result = texture(colortex5, texcoord).rgb * weight[0]; // current fragment's contribution
    
        for(int i = 1; i < 5; ++i)
        {
            result += texture(colortex5, texcoord + vec2(tex_offset.x * i, 0.0)).rgb * weight[i];
            result += texture(colortex5, texcoord - vec2(tex_offset.x * i, 0.0)).rgb * weight[i];
        }
   
   
    color = vec4(result, 1.0);
	#endif
}