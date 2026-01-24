#ifndef FOG
#define FOG
#include "/lib/atmosphere/sky.glsl"

vec3 borderFog(vec3 color, vec3 dir, float depth) {
  vec3 fogColor = skyScattering(normalize(dir));
  float dist = length(dir) / far;
  float fogFactor = exp(-24.0 * (1.0 - dist));
  float rainFogFactor = exp(-7.37 * (1.0 - dist));
  fogFactor = mix(fogFactor, rainFogFactor, wetness);
  return mix(color, fogColor, clamp(fogFactor, 0.0, 1.0));
}

vec3 atmosphericFog(vec3 color, vec3 viewPos, float depth, vec2 uv, bool isWater) {
   float dist = length(viewPos) / 83.3 ;
  vec3 sunColor = vec3(0.0);
  
  vec3 absorption = vec3(0.9373, 0.9373, 0.9373);
  vec3 inscatteringAmount = computeSkyColoring(viewPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 worldPos = feetPlayerPos + cameraPosition;
  float worldHeight = smoothstep(182, 46, worldPos.y);
  float fogSmoothReduction = smoothstep(1.0,0.38,worldHeight);
  float scatterReduce = smoothstep(0, 185, eyeBrightnessSmooth.y);
  inscatteringAmount = pow(inscatteringAmount, vec3(2.2));
  inscatteringAmount *= scatterReduce;
  absorption = pow(absorption, vec3(2.2));
  vec3 noiseOffset = vec3(0.12,0.0,0.73) * frameTimeCounter * 0.03;
  float noise = texture(fogTex,mod((worldPos.xz ) / 2 , 1024.0) / 1024.0).r;
  vec3 viewDir = normalize(viewPos);
  float smoothDepth = smoothstep(0.998, 1.0, depth);
  float VdotL = dot(viewDir, lightVector);
  float phase = henyeyGreensteinPhase(VdotL, 0.75);
  float backPhase = henyeyGreensteinPhase(VdotL, -0.25);
  sunColor = currentSunColor(sunColor) * 0.87;
  float noiseDistributionFactor = smoothstep(1.0, 0.95, noise);
  vec3 absorptionFactor = exp(
    -absorption * (dist *0.33)
  );
  if(isWater)
  {
    noise = 0.8;
  }
  vec3 phaseLighting = sunColor  * phase * scatterReduce * smoothDepth;
  vec3 scattering = inscatteringAmount * noise * worldHeight;
  vec3 totalScattering = (scattering + phaseLighting) * ENVIORNMENT_FOG_DENSITY;
  color.rgb *= absorptionFactor ;
  color.rgb += (totalScattering / absorption) * (1.0 - absorptionFactor) ;

  return color.rgb;
}
#endif //FOG
