#version 330 compatibility

#include "/lib/util.glsl"

uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;


#include "/lib/util.glsl"
#include "/lib/spaceConversions.glsl"

 bool isNight = worldTime >= 13000 && worldTime < 24000;
 bool isSunrise = worldTime <= 999;

in vec3 modelPos;
in vec3 viewPos;
in vec3 feetPlayerPos;
in mat3 tbnMatrix;
 const vec3 fogColor = vec3(0.8706, 0.949, 1.0) * 1.5;
 const vec3 skyColor = vec3(0.4275, 0.7569, 0.9922) * 1.4;
 const vec3 nightFogColor = vec3(0.0941, 0.1843, 0.3373);
 const vec3 nightskyColor = vec3(0.0235, 0.051, 0.2039);
 const vec3 earlyFogColor = vec3(0.8941, 0.5922, 0.4039) * 1.4;
 const vec3 earlySkyColor = vec3(0.2275, 0.7216, 0.8118)* 1.2;
 const vec3 lateFogColor = vec3(0.6588, 0.2549, 0.1098);
 const vec3 lateSkyColor = vec3(0.2706, 0.451, 0.5529);
 const vec3 rainHorizonColor = vec3(0.9294, 0.9294, 0.9294);
 const vec3 rainSkyColor = vec3(0.6627, 0.6627, 0.6627);

float skySmoothing(vec2 st, float pct)
{
    return  smoothstep( pct-0.04, pct, st.y) - smoothstep( pct, pct+0.04, st.y);
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
          float fogifyBlend = mix(fogify(max(upDot, 0.0), 0.024),fogify(max(upDot, 0.0), 0.025), time);
        blend = mix(zenithColor, horizonColor, fogifyBlend);
    }
    else if(worldTime >= 11500 && worldTime < 13000)
     {
        float time = smoothstep(11500, 13000, float(worldTime));
        horizonColor = mix(lateFogColor, nightFogColor, time);
        zenithColor =  mix(lateSkyColor, nightskyColor, time);
        float fogifyBlend = mix(fogify(max(upDot, 0.1), 0.035),fogify(max(upDot, 0.0), 0.015), time);
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

/* RENDERTARGETS: 0,1,2,3,5,6,10*/
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 specMap;
layout(location = 4) out vec4 extractedColor;
layout(location = 5) out vec4 specularLighting;
layout(location = 6) out vec4 geoNormal;

void main() {
if (renderStage == MC_RENDER_STAGE_STARS) {
		color = glcolor * 5.5;
	} else {
		vec3 pos = viewPos;
		color = vec4(calcSkyColor(normalize(pos)), 1.0);
	}
  vec3 normalMaps = texture(normals, texcoord).rgb;
	normalMaps = normalMaps * 2 - 1;
	normalMaps.z = sqrt(1.0 - dot(normalMaps.xy, normalMaps.xy));
	vec3 mappedNormal = tbnMatrix * normalMaps;
	
	

	geoNormal = vec4(normal * 0.5 + 0.5, 1.0);

	encodedNormal = vec4(mappedNormal * 0.5 + 0.5, 1.0);
	extractedColor = color;
	specMap = texture(specular, texcoord);
}