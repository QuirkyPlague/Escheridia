
#ifndef SKY_GLSL
#define SKY_GLSL

#include "/lib/util.glsl"
#include "/lib/spaceConversions.glsl"

 bool isNight = worldTime >= 13000 && worldTime < 24000;
 bool isSunrise = worldTime <= 999;

 const vec3 horizColor = vec3(0.7333, 0.9647, 1.0);
 const vec3 zenColor = vec3(0.1451, 0.6, 0.9725);
 const vec3 nightFogColor = vec3(0.0392, 0.0471, 0.1294);
 const vec3 nightskyColor = vec3(0.0039, 0.0118, 0.0549);
 const vec3 earlyFogColor = vec3(1.0, 0.502, 0.1882);
 const vec3 earlySkyColor = vec3(0.3294, 0.898, 1.0);
 const vec3 lateFogColor = vec3(1.0, 0.302, 0.1804);
 const vec3 lateSkyColor = vec3(0.298, 0.5137, 0.6392);
 const vec3 rainHorizonColor = vec3(0.7373, 0.7373, 0.7373);
 const vec3 rainSkyColor = vec3(0.4118, 0.4118, 0.4118);

float skySmoothing(vec2 st, float pct)
{
    return  smoothstep( pct-0.04, pct, st.y) - smoothstep( pct, pct+0.04, st.y);
}

float fogify(float x, float w) {
	
    return w / (x * x  + w);
}



vec3 calcSkyColor(vec3 pos) {
   vec3 horizonColor = horizColor;
   vec3 zenithColor = zenColor;
     float upDot = dot(pos, gbufferModelView[1].xyz); //not much, whats up with you?
        vec3 blend;
  
    if(worldTime >= 0 && worldTime < 1000)
    {
        float time = smoothstep(0, 1000, float(worldTime));
        horizonColor = mix(earlyFogColor, horizColor, time);
        zenithColor =  mix(earlySkyColor, zenColor, time);
        float fogifyBlend = mix(fogify(max(upDot, 0.0), 0.025),fogify(max(upDot, 0.0), 0.005), time);
        blend = mix(zenithColor, horizonColor, fogifyBlend);
    }
    else if(worldTime >= 1000 && worldTime < 11500)
     {
        float time = smoothstep(10000, 11500, float(worldTime));
        horizonColor = mix(horizColor, earlyFogColor, time);
        zenithColor =  mix(zenColor, earlySkyColor, time);
          float fogifyBlend = mix(fogify(max(upDot, 0.0), 0.005),fogify(max(upDot, 0.0), 0.035), time);
        blend = mix(zenithColor, horizonColor, fogifyBlend);
    }
    else if(worldTime >= 11500 && worldTime < 13000)
     {
        float time = smoothstep(11500, 13000, float(worldTime));
        horizonColor = mix(lateFogColor, nightFogColor, time);
        zenithColor =  mix(lateSkyColor, nightskyColor, time);
        float fogifyBlend = mix(fogify(max(upDot, 0.0), 0.035),fogify(max(upDot, 0.0), 0.015), time);
        blend = mix(zenithColor, horizonColor, fogifyBlend);
    
    }
    else if(worldTime >= 13000 && worldTime < 24000)
     {
        float time = smoothstep(23215, 24000, float(worldTime));
        horizonColor = mix(nightFogColor, earlyFogColor, time);
        zenithColor =  mix(nightskyColor, earlySkyColor, time);
         float fogifyBlend = mix(fogify(max(upDot, 0.0), 0.015),fogify(max(upDot, 0.0), 0.025), time);
        blend = mix(zenithColor, horizonColor, fogifyBlend);
    }

    vec3 currentZenithColor = zenithColor;
    vec3 currentHorizonColor = horizonColor;

     if(rainStrength <= 1.0 && rainStrength > 0.0 && !isNight)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    zenithColor = mix(currentZenithColor, rainSkyColor, dryToWet);
    horizonColor = mix(currentHorizonColor, rainHorizonColor, dryToWet);
    float fogifyBlend = mix(fogify(max(upDot, 0.0), 0.015),fogify(max(upDot, 0.0), 0.025), dryToWet);
    blend = mix(zenithColor, horizonColor, fogifyBlend);
  }
  else if(rainStrength <= 1.0 && rainStrength > 0.0 && isNight)
  {
     float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    zenithColor = mix(currentZenithColor, rainSkyColor, dryToWet) * 0.3;
    horizonColor = mix(currentHorizonColor, rainHorizonColor, dryToWet) * 0.3;
    float fogifyBlend = mix(fogify(max(upDot, 0.0), 0.015),fogify(max(upDot, 0.0), 0.025), dryToWet);
    blend = mix(zenithColor, horizonColor, fogifyBlend);
  }

   
        return blend;
    
}

vec3 applySky(vec3 color, vec2 texcoord, float depth)
{
        vec3 viewPos = screenToView(texcoord, depth);
        vec3 normalViewPos = normalize(viewPos.xyz);
		color = vec3(calcSkyColor(normalize(normalViewPos)));
        return color;
}

#endif