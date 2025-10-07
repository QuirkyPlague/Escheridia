#ifndef LIGHTING
#define LIGHTING

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/brdf.glsl"
#include "/lib/phaseFunctions.glsl"

//Sun/moon
const vec4 sunlightColor = vec4(1.0, 0.8784, 0.6353, 1.0);
const vec4 morningSunlightColor = vec4(1.0, 0.5529, 0.3451, 1.0);
const vec4 eveningSunlightColor = vec4(1.0, 0.4471, 0.2118, 1.0);
const vec4 moonlightColor = vec4(0.0471, 0.0941, 0.2157, 1.0);

const vec4 skylightColor = vec4(0.549, 0.6706, 0.9765, 0.791);
const vec4 morningSkylightColor = vec4(0.4863, 0.6667, 0.8745, 0.651);
const vec4 eveningSkylightColor = vec4(0.3294, 0.4549, 0.8235, 0.621);
const vec4 nightSkylightColor = vec4(0.0353, 0.0784, 0.1882, 0.451);

const vec4 blocklightColor = vec4(1.0, 0.7961, 0.5451,1.0);
const vec4 ambientColor = vec4(0.2235, 0.2235, 0.2235, 1.0);

vec3 getLighting(vec3 color, vec2 lightmap, vec3 normal, vec3 shadow, vec3 H, vec3 F0, float roughness, vec3 V, float ao, float sss, float VdotL, bool isMetal)
{   
    float t = fract(worldTime / 24000.0);
    const int keys = 7;
    const float keyFrames[keys] = float[keys](
    0.0,        //sunrise
    0.0417,     //day
    0.25,       //noon
    0.4792,     //sunset
    0.5417,     //night
    0.8417,     //midnight
    1.0         //sunrise
    );
    
    //sunlight Keyframes
    const vec4 sunCol[keys] = vec4[keys](
    morningSunlightColor,
    sunlightColor,
    sunlightColor,
    eveningSunlightColor,
    moonlightColor,
    moonlightColor,
    morningSunlightColor
    );

    const vec4 skyCol[keys] = vec4[keys](
    morningSkylightColor,
    skylightColor,
    skylightColor,
    eveningSkylightColor,
    nightSkylightColor,
    nightSkylightColor,
    morningSkylightColor
  );

    int i = 0;
    //assings the keyframes
    for (int k = 0; k < keys - 1; ++k) {
        i += int(step(keyFrames[k + 1], t));
    }
    i = clamp(i, 0, keys - 2);

    //Interpolation factor based on the time
    float timeInterp = (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
    timeInterp = smoothstep(0.0, 1.0, timeInterp);
    
    vec3 sunlight =  mix(sunCol[i].rgb, sunCol[i + 1].rgb, timeInterp);
    float sunIntensity = mix(sunCol[i].a, sunCol[i + 1].a, timeInterp);
    sunlight *= sunIntensity;

    vec3 skylight = mix(skyCol[i].rgb, skyCol[i + 1].rgb, timeInterp) * lightmap.g;
    float skyIntensity = mix(skyCol[i].a, skyCol[i + 1].a, timeInterp);;
    skylight *= skyIntensity;
    skylight += max(5.95 * pow(skylight, vec3(2.55)), 0.0);
    skylight *= min(1.07 * pow(skylight, vec3(0.1)), 0.67);

    vec3 blocklight = blocklightColor.rgb * lightmap.r;
    blocklight += max(4.9 * pow(blocklight, vec3(0.75)), 0.0);
    blocklight *= 1.55;
    blocklight *= clamp(min(0.17 * pow(blocklight, vec3(0.8)), 5.2), 0.0, 1.0);

    vec3 ambientLight = ambientColor.rgb * color;
    vec3 indirect = (skylight + blocklight) * ao;
    float metalMask = isMetal ? 1.0 : 0.0;
    indirect = mix(indirect, indirect * 0.35, metalMask);
    vec3 specular = brdf(color, F0, sunlight,normal, H, V, roughness, indirect, shadow, isMetal);

    float hasSSS = step(64.0 / 255.0, sss); 
    float phase = mix(CS(0.65, VdotL) * 1.5, henyeyGreensteinPhase(VdotL, -0.15), 1.0 - clamp(VdotL, 0,1)) ;
    vec3 scatter = (sunlight * 2) * phase * shadow * color;
    vec3 baseScatter = sunlight * shadow * color;
    scatter += baseScatter;
    scatter *= hasSSS;

    return  specular + ambientLight + scatter;

}

vec3 currentSunColor(vec3 color) {
  float t = fract(worldTime / 24000.0);
    const int keys = 7;
    const float keyFrames[keys] = float[keys](
    0.0,        //sunrise
    0.0417,     //day
    0.25,       //noon
    0.4792,     //sunset
    0.5417,     //night
    0.8417,     //midnight
    1.0         //sunrise
    );
    
    //sunlight Keyframes
    const vec4 sunCol[keys] = vec4[keys](
    morningSunlightColor,
    sunlightColor,
    sunlightColor,
    eveningSunlightColor,
    moonlightColor,
    moonlightColor,
    morningSunlightColor
    );


    int i = 0;
    //assings the keyframes
    for (int k = 0; k < keys - 1; ++k) {
        i += int(step(keyFrames[k + 1], t));
    }
    i = clamp(i, 0, keys - 2);

    //Interpolation factor based on the time
    float timeInterp = (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
    timeInterp = smoothstep(0.0, 1.0, timeInterp);
    
    vec3 sunlight =  mix(sunCol[i].rgb, sunCol[i + 1].rgb, timeInterp);
    float sunIntensity = mix(sunCol[i].a, sunCol[i + 1].a, timeInterp);
    sunlight *= sunIntensity;
    return sunlight;
}

#endif //LIGHTING_GLSL
