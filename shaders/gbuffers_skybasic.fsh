#version 410 compatibility

#include "/lib/util.glsl"

in vec4 glcolor;


vec3 sunCol = vec3(1.0, 0.3, 0.05);
 vec3 fogColor = vec3(0.6118, 0.9765, 0.9882);
 vec3 skyColor = vec3(0.2118, 0.3686, 1.0);
 vec3 nightFogColor = vec3(0.0588, 0.149, 0.2078);
 vec3 nightSkyColor = vec3(0.0319, 0.0639, 0.1557);
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
        zenithColor =  mix(lateSkyColor, nightSkyColor, time);
    }
    else if(worldTime >= 13000 && worldTime < 24000)
     {
        float time = smoothstep(23215, 24000, float(worldTime));
        horizonColor = mix(nightFogColor, earlyFogColor, time);
        zenithColor =  mix(nightSkyColor, earlySkyColor, time);
    }

    vec3 currentSkyColor = zenithColor;
    vec3 currentHorizonColor = horizonColor;

    if(rainStrength <= 1.0 && rainStrength > 0.0)
    {
        float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
        horizonColor = mix(currentHorizonColor, rainFogColor, dryToWet);
        zenithColor =  mix(currentSkyColor, rainSkyColor, dryToWet);
    }

     float upDot = dot(pos, gbufferModelView[1].xyz); //not much, whats up with you?
        return mix(zenithColor, horizonColor, fogify(max(upDot, 0.01), 0.03));
    
}


vec3 screenToView(vec3 screenPos) {
    vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
    vec4 tmp = gbufferProjectionInverse * ndcPos;
    return tmp.xyz / tmp.w;
}

/* RENDERTARGETS: 0,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 Skycolor;
void main() {
    if (renderStage == MC_RENDER_STAGE_STARS) {
        color = glcolor *2 ;
    } else {
       vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
        vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
        viewPos /= viewPos.w;
        vec3 normalViewPos = normalize(viewPos.xyz);
		color = vec4(calcSkyColor(normalize(normalViewPos)), 1.0);
    }
    #if DO_AMD_SKY_FIX
    Skycolor = color / 18;
    #endif
    color.rgb = pow(color.rgb, vec3(2.2));
}


