#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/atmosphere/volumetrics.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	float depth = texture(depthtex0, texcoord).r;
 	vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components
	vec3 baseNormal = texture(colortex4, texcoord).rgb;
  	vec3 normal = normalize((baseNormal - 0.5) * 2.0);
  	//space conversions
  	vec3 screenPos = vec3(texcoord.xy, depth);
  	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 shadowViewPos_start = (shadowModelView * vec4(vec3(0.0), 1.0)).xyz;
  	vec4 shadowClipPos_start = shadowProjection * vec4(shadowViewPos_start, 1.0);
	vec3 noise =  blue_noise(floor(gl_FragCoord.xy), frameCounter, 24);

  	vec3 shadowViewPos_end = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  	vec4 shadowClipPos_end = shadowProjection * vec4(shadowViewPos_end, 1.0);

  	color.rgb += volumetricRaymarch(
    shadowClipPos_start,
    shadowClipPos_end,
    24,
    noise.x,
    feetPlayerPos,
    color.rgb,
    normal,
    lightmap
  );
  
}