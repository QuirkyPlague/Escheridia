#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/clouds.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  vec2 lightmap = texture(colortex1, texcoord).rg;
  float depth = texture(depthtex0, texcoord).r;
  if (depth == 1.0) return;

  //space conversions
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
  vec3 noiseB = blue_noise(floor(gl_FragCoord.xy), frameCounter, 128);
  float distToTerrain = (depth == 1.0) ? -1.0 : length(viewPos) * CLOUD_SCALE;

  vec3 origin = vec3(0.0, CLOUD_SCALE * (eyeAltitude - 64.0), 0.0) + CLOUD_SCALE * gbufferModelViewInverse[3].xyz;
  vec3 direction =  mat3(gbufferModelViewInverse) * normalize(viewPos);
  vec3 clouds = cloudRaymarch(origin, direction, 128, noiseB, feetPlayerPos, distToTerrain);
  
  //color.rgb *= clouds;
}
