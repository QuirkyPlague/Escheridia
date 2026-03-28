#ifndef LIGHTING
#define LIGHTING

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
#include "/lib/brdf.glsl"
#include "/lib/phaseFunctions.glsl"
#include "/lib/tonemapping.glsl"

//Sun/moon
const vec4 sunlightColor = vec4(1.0, 0.860, 0.692, 1.18);
const vec4 noonSunlightColor = vec4(0.6824, 0.6824, 0.6824, 1.0);
const vec4 morningSunlightColor = vec4(1.0, 0.73, 0.4033, 2.45);
const vec4 eveningSunlightColor = vec4(0.9569, 0.4745, 0.2333, 1.0);
const vec4 moonlightColor = vec4(0.4039, 0.4863, 0.7608, 1.35);

const vec4 skylightColor = vec4(0.6902, 0.8196, 0.9961, 1.0);
const vec4 morningSkylightColor = vec4(0.7137, 0.8235, 0.9569, 0.991);
const vec4 eveningSkylightColor = vec4(0.6353, 0.7333, 0.851, 0.731);
const vec4 nightSkylightColor = vec4(0.4784, 0.4784, 0.741, 1.72);

const vec4 blocklightColor = vec4(1.7, 0.8, 0.5843, 1.4);
const vec4 ambientColor = vec4(0.005);
 vec4 caveAmbient = vec4(0.3255, 0.3804, 0.4314, 1.0);
const vec3 rainTint = vec3(0.6122, 0.5549, 0.4627);

vec3 getLighting(
    vec3 color,
    vec2 lightmap,
    vec3 normal,
    vec3 shadow,
    vec3 H,
    vec3 F0,
    float roughness,
    vec3 V,
    float ao,
    float sss,
    float VdotL,
    bool isMetal,
    float materialAo,
    vec3 faceNormal,
   vec3 blocklightCol) {
    
  
   
    float t = fract(worldTime / 24000.0);
    const int keys = 7;
    const float keyFrames[keys] = float[keys](
        0.0, //sunrise
        0.0417, //day
        0.415, //noon
        0.5122, //sunset
        0.5417, //night
        0.9527, //midnight
        1.0 //sunrise
    );
        //sunlight Keyframes
        const vec4 sunCol[keys] = vec4[keys](
            morningSunlightColor,
            sunlightColor,
            noonSunlightColor,
            eveningSunlightColor,
            moonlightColor,
            moonlightColor,
            morningSunlightColor);

        const vec4 skyCol[keys] = vec4[keys](
            morningSkylightColor,
            skylightColor,
            skylightColor,
            eveningSkylightColor,
            nightSkylightColor,
            nightSkylightColor,
            morningSkylightColor);

        const float rainLight[keys] = float[keys](
            0.15,
            0.25,
            0.25,
            0.075,
            0.33,
            0.33,
            0.15);

        int i = 0;
        //assings the keyframes
        for (int k = 0; k < keys - 1; ++k) {
            i += int(step(keyFrames[k + 1], t));
        }
        i = clamp(i, 0, keys - 2);

        //Interpolation factor based on the time
        float timeInterp =
        (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
        timeInterp = smoothstep(0.0, 1.0, timeInterp);

        vec3 sunlight = mix(sunCol[i].rgb, sunCol[i + 1].rgb, timeInterp);
        float sunIntensity = mix(sunCol[i].a, sunCol[i + 1].a, timeInterp);
        float rain = mix(rainLight[i], rainLight[i + 1], timeInterp);
        float sunHeight = dot(worldLightVector, vec3(0.0, 1.0, 0.0));
        float shadowFade = smoothstep(0.005, 0.1, worldLightVector.y);
        float shadowSmooth = exp(-5.0 * SHADOW_DISTANCE);
        float shadowSmoothFade = smoothstep(0.0, 1.0, shadowSmooth);

        float wetMask = step(0.0, wetness);
        float wetFactor = wetness * hotBiomeSmooth;
        vec3 baseSunlight = sunlight;
        vec3 wetSunlight = mix(baseSunlight, rainTint, wetFactor);
        float wetMul = mix(1.0, rain, wetFactor);
        sunlight *= mix(vec3(1.0), wetSunlight, wetMask);
        sunlight *= mix(1.0, wetMul, wetMask);
        float sunLum = luminance(sunlight * sunIntensity);
        sunlight *= sunLum;
        sunlight *= shadowFade;
       
        vec3 skylight =
        mix(skyCol[i].rgb, skyCol[i + 1].rgb, timeInterp) * lightmap.g;
        skylight = mix(skylight, vec3(0.3961, 0.4627, 0.5451) * rain * lightmap.g * 2.7, wetness * hotBiomeSmooth);
        float skyIntensity = mix(skyCol[i].a, skyCol[i + 1].a, timeInterp);
        float skyLum = luminance(skylight * skyIntensity);
        skylight *= skyLum;
        skylight *= max(1.95 * pow(skylight, vec3(2.55)), 0.0);
        skylight += min(1.7 * pow(skylight, vec3(1.25)), 1.9);

        
        vec3 blocklight = blocklightCol;
        float blocklightIntensity = blocklightColor.a;
        float blocklightLum = luminance(blocklight * blocklightIntensity);
        blocklight *= blocklightIntensity;
        blocklight *= max(16.59 * pow(blocklight, vec3(0.135)), 0.0);
        blocklight += min(0.57 * pow(blocklight, vec3(1.25)), 6.9);
         

        

        float faceNdl = dot(faceNormal, worldLightVector);

        float hasSSS = step(64.0 / 255.0, sss);
        float LdotH = dot(worldLightVector, H);
        float VdotH = dot(V, H);
        vec3 sssFresnel = fresnelSchlick(max(abs(LdotH), 0.0001), vec3(0.04));
        float phase =
        henyeyGreensteinPhase(VdotL, 0.72) *8;
        float uniformPhase = 1.0 / (4.0 * PI);
        vec3 scatter = vec3(0.0);
        
        scatter = sunlight * phase * shadow;
        vec3 baseScatter = sunlight * shadow;
        scatter += baseScatter * 2.75 * (1.0 - sssFresnel)  ;
        scatter *= hasSSS;
        scatter *= sss ;
        vec3 ambientSSS = skylight * 0.55 * sss;
        vec3 blockSSS = blocklight * 4  * sss;
        vec3 indirectSSS = ambientSSS + blockSSS * ao  * uniformPhase;
        indirectSSS = mix(indirectSSS * 0.03, indirectSSS, roughness);
        scatter += indirectSSS;

        float faceNdlMask = step(1e-6, faceNdl);
        scatter *= mix(1.0, 0.45, faceNdlMask);

        float smoothLightmap = clamp(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y),0,1);
        float ambientFactor = smoothstep(141, 0, eyeBrightnessSmooth.y);

        //ao *= ao * (1.0 - float(shadow));
        float metalMask = isMetal ? 1.0 : 0.0;
        caveAmbient = mix(caveAmbient, caveAmbient *0.25, metalMask);
        vec3 ambientLight = (mix(ambientColor.rgb,caveAmbient.rgb * 0.095, ambientFactor)* ao * materialAo) * color  ;
        ambientLight = mix(ambientLight, ambientLight * rain, wetness * hotBiomeSmooth);
        
        vec3 indirect = (skylight + blocklight) * ao * materialAo;
        
        bool noSky = lightmap.g < smoothstep(0.0, 0.682, lightmap.g);
        vec3 metalIndirect = mix(indirect * 0.0,indirect  * 0 , smoothLightmap);
       // indirect = mix(indirect, metalIndirect, metalMask);
        vec3 metalAmbient = mix(ambientLight* 5, ambientLight  * 3, smoothLightmap);
        ambientLight = mix(ambientLight, metalAmbient, metalMask);
        vec3 specular = brdf(
            color,
            F0,
            sunlight,
            normal,
            H,
            V,
            roughness,
            indirect,
            shadow,
            isMetal,
            smoothLightmap);

        //specular = pow(specular, vec3(2.2));

        scatter *= color;

        return specular + scatter + ambientLight ;
    }

    vec3 currentSunColor(vec3 color) {
        float t = fract(worldTime / 24000.0);
        const int keys = 7;
        const float keyFrames[keys] = float[keys](
            0.0, //sunrise
            0.0417, //day
            0.415, //noon
            0.5122, //sunset
            0.5417, //night
            0.9527, //midnight
            1.0); //sunrise;

            //sunlight Keyframes
            const vec4 sunCol[keys] = vec4[keys](
                morningSunlightColor,
                sunlightColor,
                sunlightColor,
                eveningSunlightColor,
                moonlightColor * 1.3,
                moonlightColor * 1.3,
                morningSunlightColor );

            int i = 0;
            //assings the keyframes
            for (int k = 0; k < keys - 1; ++k) {
                i += int(step(keyFrames[k + 1], t));
            }
            i = clamp(i, 0, keys - 2);

            //Interpolation factor based on the time
            float timeInterp =
            (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
            timeInterp = smoothstep(0.0, 1.0, timeInterp);
            float phaseIncFactor = smoothstep(225, 0, eyeBrightnessSmooth.y);
            float ambientMult = mix(1.0, 0.0, phaseIncFactor);
            vec3 sunlight = mix(sunCol[i].rgb, sunCol[i + 1].rgb, timeInterp);
            float sunIntensity = mix(sunCol[i].a, sunCol[i + 1].a, timeInterp);
            float sunHeight = dot(worldLightVector, vec3(0.0, 1.0, 0.0));
            float shadowFade = smoothstep(0.05, 0.1, worldLightVector.y);

            float wetMask = step(0.0, wetness);
            float wetFactor = wetness * hotBiomeSmooth;
            vec3 baseSunlight = sunlight;
            vec3 wetSunlight = mix(baseSunlight, rainTint, wetFactor);
            float wetMul = mix(1.0, 0.77, wetFactor);
            sunlight *= mix(vec3(1.0), wetSunlight, wetMask);
            sunlight *= mix(1.0, wetMul, wetMask);
            float sunLum = luminance(sunlight * sunIntensity);
            sunlight *= sunLum;
            sunlight *= shadowFade;
            return sunlight;
        }

#endif //LIGHTING_GLSL
        