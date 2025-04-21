#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/tonemapping.glsl"


uniform float exposure;




in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
    
    vec3 exposureCompensation = vec3 (1.0/2.2);
 
    #if TONEMAPPING_TYPE == 1
    
        color.rgb = uncharted2(color.rgb);
    
    #elif TONEMAPPING_TYPE == 0
    
         color.rgb = aces(color.rgb);
    #elif TONEMAPPING_TYPE == 2
            color.rgb = reinhard_jodie(color.rgb);  
    #elif TONEMAPPING_TYPE == 3
     color.rgb = agx(color.rgb); 
    #else
        color.rgb = (pow(color.rgb, exposureCompensation));
    #endif

    color.rgb = CSB(color.rgb, brightness, saturation, contrast);
    
}