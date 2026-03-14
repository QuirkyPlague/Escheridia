#version 430 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  vec4 translucents = texture(colortex15, texcoord);
  
  float translucentAlpha = translucents.a;
  vec2 lightmap = texture(colortex1, texcoord).rg;
  float depth = texture(depthtex0, texcoord).r;

  vec3 translucentColor = translucents.rgb;
 
  //space conversions
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
  color.rgb  = mix(color.rgb,translucentColor , clamp(translucentAlpha, 0,1));

  
}
