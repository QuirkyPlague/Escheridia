#version 410 compatibility

#include "/lib/util.glsl"

in vec4 glcolor;




/* RENDERTARGETS: 0,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 Skycolor;
void main() {
    if (renderStage == MC_RENDER_STAGE_STARS) {
        color = glcolor *2 ;
    
    color.rgb = pow(color.rgb, vec3(2.2));
}
}


