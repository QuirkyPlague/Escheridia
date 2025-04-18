
#ifndef SKY_GLSL
#define SKY_GLSL

#include "/lib/util.glsl"
 bool isNight = worldTime >= 13000 && worldTime < 24000;
 bool isSunrise = worldTime <= 999;
vec3 sunCol = vec3(1.0, 0.3, 0.05);
vec3 fogColor = vec3(0.8784, 0.9843, 0.9686);
 vec3 skyColor = vec3(0.1216, 0.2902, 0.9725);
 vec3 nightFogColor = vec3(0.0157, 0.0353, 0.051);
 vec3 nightskyColor = vec3(0.0, 0.0039, 0.0235);
 vec3 earlyFogColor = vec3(1.0, 0.502, 0.1882);
 vec3 earlySkyColor = vec3(0.3294, 0.898, 1.0);
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



vec3 calcSkyColor(vec3 pos) {
   vec3 horizonColor = fogColor;
   vec3 zenithColor = skyColor;
     float upDot = dot(pos, gbufferModelView[1].xyz); //not much, whats up with you?
        vec3 blend;
  
    if(worldTime >= 0 && worldTime < 1000)
    {
        float time = smoothstep(0, 1000, float(worldTime));
        horizonColor = mix(earlyFogColor, fogColor, time);
        zenithColor =  mix(earlySkyColor, skyColor, time);
        float fogifyBlend = mix(fogify(max(upDot, 0.0), 0.025),fogify(max(upDot, 0.0), 0.005), time);
        blend = mix(zenithColor, horizonColor, fogifyBlend);
    }
    else if(worldTime >= 1000 && worldTime < 11500)
     {
        float time = smoothstep(10000, 11500, float(worldTime));
        horizonColor = mix(fogColor, earlyFogColor, time);
        zenithColor =  mix(skyColor, earlySkyColor, time);
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

    vec3 currentSkyColor = zenithColor;
    vec3 currentHorizonColor = horizonColor;
    

   
        return blend;
    
}
vec3 screenToView(vec3 screenPos) {
    vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
    vec4 tmp = gbufferProjectionInverse * ndcPos;
    return tmp.xyz / tmp.w;
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

#endif