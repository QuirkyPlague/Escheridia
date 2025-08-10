#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/util.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/blockID.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 3 */
layout(location = 0) out vec4 color;

void main() {
  float depth = texture(depthtex0, texcoord).r;
  float depth1 = texture(depthtex1, texcoord).r;
  
  //space conversions
  vec3 screenPos = vec3(texcoord.xy, depth);
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec4 waterMask = texture(colortex4, texcoord);
  int blockID = int(waterMask) + 100;
  bool isWater = blockID == WATER_ID;
  float jitter = IGN(gl_FragCoord.xy, frameCounter);
  int stepCount = GODRAYS_SAMPLES;

  #if VOLUMETRIC_LIGHTING == 1
  color.rgb = sampleGodrays(color.rgb, texcoord, feetPlayerPos, depth);

  #elif VOLUMETRIC_LIGHTING == 2

  const float shadowMapPixelSize = 1.0 / float(SHADOW_RESOLUTION);
  float sampleRadius = SHADOW_SOFTNESS * shadowMapPixelSize * 0.74;
  #if PIXELATED_LIGHTING == 1
  sampleRadius = SHADOW_SOFTNESS * shadowMapPixelSize * 0.54;

  feetPlayerPos = feetPlayerPos + cameraPosition;
  feetPlayerPos = floor(feetPlayerPos * 8 + 0.01) / 8;
  feetPlayerPos -= cameraPosition;
  #endif
	vec3 shadowViewPos_start = (shadowModelView * vec4(vec3(0.0), 1.0)).xyz;
	vec4 shadowClipPos_start = shadowProjection * vec4(shadowViewPos_start, 1.0);
	vec3 shadowNDCPos_start = shadowClipPos_start.xyz / shadowClipPos_start.w;
	vec3 shadowScreenPos_start = shadowNDCPos_start * 0.5 + 0.5;

	vec3 shadowViewPos_end = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos_end = shadowProjection * vec4(shadowViewPos_end, 1.0);
	vec3 shadowNDCPos_end = shadowClipPos_end.xyz / shadowClipPos_end.w;
	vec3 shadowScreenPos_end = shadowNDCPos_end * 0.5 + 0.5;
   float inverseStep = 1.0 / float(stepCount);
	vec4 shadowStepSize = (shadowClipPos_end - shadowClipPos_start) * inverseStep;
  vec4 shadowPos = shadowClipPos_start + jitter * shadowStepSize;
  
  vec3 worldPos = feetPlayerPos + cameraPosition;
 
  float dist =length(feetPlayerPos) / (inverseStep);
  

	vec3 scatterF = vec3(0.0011, 0.0018, 0.0038);
  
	vec3 absorbF = vec3(0.2706, 0.4549, 0.8471);
	vec3 transmission = vec3(1.0);
	vec3 scatter = vec3(0.0, 0.0, 0.0);
	vec3 shadow;
  float VoL = dot(normalize(feetPlayerPos), worldLightVector);
  vec3 sunColor;
  sunColor = currentSunColor(sunColor);
  float phase = CS(VL_ANISO, VoL);
float waveFalloff = length(feetPlayerPos) / far;
  float waveIntensityRolloff = exp(
    0.1 * WAVE_INTENSITY * (0.04 - waveFalloff)
  );
  

  float minHeight = VOLUMETRIC_MIN_HEIGHT;
  float maxHeight = VOLUMETRIC_MAX_HEIGHT;

  float worldSmooth = smoothstep(maxHeight, minHeight, worldPos.y);

    for(int i = 0; i < GODRAYS_SAMPLES; i++) 
    {
		shadowPos += shadowStepSize;
    
      #if DO_VL_PCF == 1
      for (int i = 0; i < SHADOW_SAMPLES; i++) {
      vec2 offset = vogelDisc(i, SHADOW_SAMPLES, jitter) * sampleRadius;
      vec4 offsetShadowClipPos = shadowPos + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadow += getShadow(shadowScreenPos);
    }
    shadow /=  float(SHADOW_SAMPLES); // divide sum by count, getting average shadow
    #else
    vec4 distortedShadowPos = shadowPos;
    distortedShadowPos.xyz = distortShadowClipPos(distortedShadowPos.xyz);
    vec3 shadowNDC = distortedShadowPos.xyz;
    vec3 shadowScreen = shadowNDC * 0.5 + 0.5;
		shadow = getShadow(shadowScreen);
    #endif

		transmission *= exp(-dist * absorbF);

		vec3 sampleInscatter = scatterF * phase * dist *(sunColor * VOLUMETRIC_FOG_DENSITY) * shadow;
    vec3 sampleExtinction = absorbF * VOLUMETRIC_FOG_DENSITY;
    float sampleTransmittance = exp(-dist * VOLUMETRIC_FOG_DENSITY * 0.2);
    scatter +=  (sampleInscatter - sampleInscatter * sampleTransmittance) / sampleExtinction;
    transmission *= sampleTransmittance;
    
    }
    scatter *= 0.003 * VOLUMETRIC_FOG_DENSITY;
    
    #ifdef DO_FOG_HEIGHT
    scatter*= waveIntensityRolloff;
    scatter = mix(scatter * 0.3, scatter * 5, worldSmooth);
    
    #endif
    
	color.rgb = mix(color.rgb, transmission + scatter, 1.0 + wetness);
  if(depth ==1)
    {
      color.rgb = mix(color.rgb, (transmission + scatter) * 0.15, 1.0 + wetness);
    }
    
	#endif
	
	
}

