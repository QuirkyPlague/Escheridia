#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/util.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 3 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  float depth = texture(depthtex0, texcoord).r;
  //space conversions
  vec3 screenPos = vec3(texcoord.xy, depth);
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

  float jitter = IGN(gl_FragCoord.xy, frameCounter);
  int stepCount = GODRAYS_SAMPLES;

  #if VOLUMETRIC_LIGHTING == 1
  color.rgb = sampleGodrays(color.rgb, texcoord, feetPlayerPos, depth);
  #endif
  /*
	vec3 shadowViewPos_start = (shadowModelView * vec4(vec3(0.0), 1.0)).xyz;
	vec4 shadowClipPos_start = shadowProjection * vec4(shadowViewPos_start, 1.0);
	vec3 shadowNDCPos_start = shadowClipPos_start.xyz / shadowClipPos_start.w;
	vec3 shadowScreenPos_start = shadowNDCPos_start * 0.5 + 0.5;

	vec3 shadowViewPos_end = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos_end = shadowProjection * vec4(shadowViewPos_end, 1.0);
	vec3 shadowNDCPos_end = shadowClipPos_end.xyz / shadowClipPos_end.w;
	vec3 shadowScreenPos_end = shadowNDCPos_end * 0.5 + 0.5;

	vec3 shadowStepSize = (shadowScreenPos_end - shadowScreenPos_start) / stepCount;
    vec3 shadowPos = shadowScreenPos_start + jitter * shadowStepSize;
    float dist = length(shadowPos) / far;

	const vec3 scatterF = vec3(0.0113, 0.0151, 0.0211);
	const vec3 absorbF = vec3(1.0, 1.0, 1.0);

	vec3 transmission = vec3(1.0);
	vec3 scatter = vec3(0.0, 0.0, 0.0);
	vec3 shadow;
    for(int i = 0; i < GODRAYS_SAMPLES; i++) 
    {
		shadowPos += shadowStepSize;
		shadow = getShadow(shadowPos);
		transmission *= exp(-dist * absorbF);
		scatter += scatterF * shadow * transmission;
		
	}
	
	//color.rgb = color.rgb * transmission + scatter;
	float VoL = dot(normalize(feetPlayerPos), worldLightVector);
	//color.rgb *= HG(0.25, VoL);
	*/
}

