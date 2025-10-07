#version 400 compatibility

#include "/lib/uniforms.glsl"
uniform sampler2D gtexture;

#include "/lib/util.glsl"
#include "/lib/atmosphere/skyColor.glsl"
#include "/lib/blockID.glsl"

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in mat3 tbnMatrix;
in vec3 modelPos;
in vec3 viewPos;
in vec3 feetPlayerPos;
in vec3 worldPos;
/* RENDERTARGETS: 0,10 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 reflCloud;
void main() {
  color.a = 0.1;
  color = texture(gtexture, texcoord) * glcolor;

  float depth = texture(colortex0, texcoord).r;
  float depth1 = texture(depthtex1, texcoord).r;

  float dist0 = length(viewPos);
  float dist1 = length(gl_FragCoord.z);
  float dist = max(0, dist1 - dist0);

  float cloudFade = exp(-dist * 0.5);
  color *= cloudFade;
 

}
