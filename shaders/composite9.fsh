#version 330 compatibility

#include "/lib/util.glsl"
in vec2 texcoord;

 float exposure = BLOOM_INTENSITY;
bool inWater = isEyeInWater == 1.0;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;


void main() {
	color = texture(colortex0, texcoord);
	const float gamma = 2.2;
    vec3 hdrColor = texture(colortex0, texcoord).rgb;      
    vec3 bloomColor = texture(colortex5, texcoord).rgb;
    hdrColor += bloomColor; // additive blending
    // tone mapping
    vec3 result = vec3(1.0) - exp(-hdrColor * exposure);
    // also gamma correct while we're at it       
    //result = pow(result, vec3(1.0 / gamma));
   if(inWater)
   {
      exposure = exposure;
   }
   //color = vec4(result, 1.0);
   
}