#version 430 compatibility

#include "/lib/tonemapping.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/postProcessing.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord) ;

  color.rgb = TonemapACES(color.rgb);
    color.rgb = pow(color.rgb, vec3(1.0 / 2.2));
  color.rgb = CSB(color.rgb, BRIGHTNESS, SATURATION, CONTRAST);

 color.rgb += (blue_noise(gl_FragCoord.xy, frameCounter) - 0.5) * (1.0 / 255.0);
   

  
}
