#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/tonemapping.glsl"

in vec2 texcoord;

 float bloomStrength = 0.02;
vec3 computeBloomMix()
{
    vec3 hdr = texture(colortex0, texcoord).rgb;
    vec3 blm = texture(colortex5, texcoord).rgb;
    vec3 col = mix(hdr, blm + blm, vec3(bloomStrength));
    return col;
}

float LinearToSrgbBranchingChannel(float lin) {
    if (lin < 0.00313067)
        return lin * 12.92;
    return pow(lin, (1.0 / 2.4)) * 1.055 - 0.055;
}
vec3 LinearToSrgb(vec3 lin) {
    return vec3(LinearToSrgbBranchingChannel(lin.r),
                  LinearToSrgbBranchingChannel(lin.g),
                  LinearToSrgbBranchingChannel(lin.b));
}


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
     color.rgb = computeBloomMix();
 
    #if TONEMAPPING_TYPE == 1
    
        color.rgb = uncharted2(color.rgb);
      
    #elif TONEMAPPING_TYPE == 0
    
         color.rgb = aces(color.rgb);
    #elif TONEMAPPING_TYPE == 2
            color.rgb = reinhard_jodie(color.rgb);  
    #elif TONEMAPPING_TYPE == 3
     color.rgb = agx(color.rgb); 
    #endif

    color.rgb = CSB(color.rgb, brightness, saturation, contrast);
    
}