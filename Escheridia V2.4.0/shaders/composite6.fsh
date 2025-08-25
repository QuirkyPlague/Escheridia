#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex0, texcoord).r;
  vec2 lightmap = texture(colortex1, texcoord).rg;
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);

  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
  if (!inWater) {
    vec3 distanceFog = distanceFog(color.rgb, eyePlayerPos, texcoord, depth);
    vec3 mieFog = distanceMieFog(color.rgb, viewPos, texcoord, depth);
    vec3 fullFog = distanceFog + mieFog;
    color.rgb = fullFog;
  }

}

