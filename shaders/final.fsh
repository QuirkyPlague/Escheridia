#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/tonemapping.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 8 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
 

    #if TONEMAPPING_TYPE == 1
    
        color.rgb = uncharted2(color.rgb);
      
    #elif TONEMAPPING_TYPE == 0
    
         color.rgb = aces(color.rgb);
    #elif TONEMAPPING_TYPE == 2
            color.rgb = reinhard_jodie(color.rgb);  
    #elif TONEMAPPING_TYPE == 3
     color.rgb = agx(color.rgb); 
    #endif
   

  
    
}