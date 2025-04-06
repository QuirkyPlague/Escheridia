#version 410 compatibility

#include "/lib/util.glsl"
#include "/lib/spaceConversions.glsl"

in vec3 normal;
uniform sampler2D caustics;

 vec3 fogColor = vec3(0.2706, 0.9765, 1.0);
 vec3 skyColor = vec3(0.0, 0.2, 1.0);
 vec3 nightFogColor = vec3(0.0314, 0.0784, 0.1294);
 vec3 nightskyColor = vec3(0.0039, 0.0078, 0.051);
 vec3 earlyFogColor = vec3(1.0, 0.5765, 0.3137);
 vec3 earlySkyColor = vec3(0.4235, 0.8275, 0.898);
  vec3 lateFogColor = vec3(1.0, 0.302, 0.1804);
 vec3 lateSkyColor = vec3(0.298, 0.5137, 0.6392);
 vec3 MIE_Value = vec3(0.2549, 0.2549, 0.2549);
vec4 starColor = vec4(0.1569, 0.6471, 0.9961, 1.0);
 vec3 rainFogColor = vec3(0.7373, 0.7373, 0.7373);
 vec3 rainSkyColor = vec3(0.4118, 0.4118, 0.4118);



float skySmoothing(vec2 st, float pct)
{
    return  smoothstep( pct-0.02, pct, st.y) - smoothstep( pct, pct+0.02, st.y);
}

float fogify(float x, float w) {
	
    return w / (x * x  + w);
}

uniform float near;
uniform float far;

uniform float frameTime;
uniform float waterEnterTime;

in vec2 texcoord;
bool isNight = worldTime >= 13000 && worldTime < 24000;

vec3 calcSkyColor(vec3 pos) {
   vec3 horizonColor = fogColor;
   vec3 zenithColor = skyColor;
   
  
    if(worldTime >= 0 && worldTime < 1000)
    {
        float time = smoothstep(0, 1000, float(worldTime));
        horizonColor = mix(earlyFogColor, fogColor, time);
        zenithColor =  mix(earlySkyColor, skyColor, time);
    }
    else if(worldTime >= 1000 && worldTime < 11500)
     {
        float time = smoothstep(10000, 11500, float(worldTime));
        horizonColor = mix(fogColor, earlyFogColor, time);
        zenithColor =  mix(skyColor, earlySkyColor, time);
    }
    else if(worldTime >= 11500 && worldTime < 13000)
     {
        float time = smoothstep(11500, 13000, float(worldTime));
        horizonColor = mix(lateFogColor, nightFogColor, time);
        zenithColor =  mix(lateSkyColor, nightskyColor, time);
    }
    else if(worldTime >= 13000 && worldTime < 24000)
     {
        float time = smoothstep(23215, 24000, float(worldTime));
        horizonColor = mix(nightFogColor, earlyFogColor, time);
        zenithColor =  mix(nightskyColor, earlySkyColor, time);
    }

    vec3 currentSkyColor = zenithColor;
    vec3 currentHorizonColor = horizonColor;

    if(rainStrength <= 1.0 && rainStrength > 0.0 && !isNight)
    {
        float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
        horizonColor = mix(currentHorizonColor, rainFogColor, dryToWet);
        zenithColor =  mix(currentSkyColor, rainSkyColor, dryToWet);
    }
    else if(rainStrength <= 1.0 && rainStrength > 0.0 && isNight)
    {
        float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
        horizonColor = mix(currentHorizonColor, rainFogColor, dryToWet) / 18;
        zenithColor =  mix(currentSkyColor, rainSkyColor, dryToWet) / 18;
    }

     float upDot = dot(pos, gbufferModelView[1].xyz); //not much, whats up with you?
        return mix(zenithColor, horizonColor, fogify(max(upDot, 0.01), 0.01));
   
}
vec3 applySky(vec3 color)
{
        vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
        vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
        viewPos /= viewPos.w;
        vec3 normalViewPos = normalize(viewPos.xyz);
		color = vec3(calcSkyColor(normalize(normalViewPos)));
        return color;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  vec4 causticsTex = texture(caustics, texcoord);
  vec4 waterMask = texture(colortex8, texcoord);

  int blockID = int(waterMask) + 100;

  bool isWater = blockID == WATER_ID;
  bool inWater = isEyeInWater == 1.0;
  
  float depth = texture(depthtex0, texcoord).r;
  float depth1 = texture(depthtex1, texcoord).r;
  if(depth == 1.0){
    return;
  }
  vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
  normal = mat3(gbufferModelView) * normal;
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 viewDir = normalize(viewPos);
  vec3 reflectedColor = calcSkyColor((reflect(viewDir, normal)));

   vec3 feetPlayerPos = getFeetPlayerPos(viewPos);
    vec3 worldPos = getWorldPos(feetPlayerPos);



  #if DO_WATER_FOG == 1
  // Fog calculations
  //float dist = length(viewPos) / far;
  float dist0 = length(screenToView(texcoord, depth));
  float dist1 = length(screenToView(texcoord, depth1));
  float dist = max(0, dist1 - dist0);
  float fogFactor;
  vec3 fogColor;
  vec4 darkFogColor = vec4(0.0196, 0.1176, 0.2157, 1.0);

  vec3 absorption = vec3(0.6157, 0.2941, 0.15);
  
  vec3 scattering = color.rgb;
  vec3 LightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * LightVector;
  vec3 V = normalize((-viewDir));

  vec3 F0 = vec3(0.02);
  vec3 L = normalize(worldLightVector);
  vec3 H = normalize(V + L);

vec3 F  = fresnelSchlick(max(dot(normal, V),0.0), F0);

  if(!inWater)
	{
    if(isWater && !isNight)
    {
    fogFactor = exp(-WATER_FOG_DENSITY * clamp(dist* 0.3, 0.0, 15.0)) ;
    fogColor = exp(-absorption * clamp(dist * 0.3, 0.0, 15.0));
    color.rgb = mix(color.rgb, color.rgb * fogColor, 1 - fogFactor);
    #if DO_WATER_REFLECTION == 1
    color.rgb = mix(color.rgb, reflectedColor, F);
    #endif
    }
    else if(isWater && isNight)
    {
    fogFactor = exp(-WATER_FOG_DENSITY * clamp(dist* 0.03, 0.0, 3.0)) ;
    fogColor = exp(-absorption * clamp(dist * 1.4, 0.0, 30.0));
    color.rgb = mix(color.rgb, fogColor, 1 - fogFactor) / 4;
    color.rgb = mix(color.rgb, reflectedColor, F);
    
    }
	}
   if(inWater)
	{
    if(!isWater && !isNight)
    {
    dist = dist0;
    fogFactor = exp(-WATER_FOG_DENSITY * clamp(dist* 0.025, 0.0, 10.0)) ;
    fogColor = exp(-absorption * clamp(dist , 0.0, 20.0));
    color.rgb = mix(color.rgb, fogColor, 1 - fogFactor);
    }
	}
  #endif

  

}