#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  vec2 lightmap = texture(colortex1, texcoord).rg;
  float depth = texture(depthtex0, texcoord).r;
  
  vec4 stars = texture(colortex11, texcoord);
  vec4 SpecMap = texture(colortex3, texcoord);
  bool isMetal = SpecMap.g >= 230.0 / 255.0;
  if(isMetal) return;
  //space conversions
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
   
    if (depth == 1.0)
  {
    vec3 sky = skyScattering(eyePlayerPos);
    vec3 sun = getSun(normalize(eyePlayerPos));
    color.rgb = sky + sun + stars.rgb;
    
  }
}
