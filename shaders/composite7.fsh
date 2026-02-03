#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blockID.glsl"
#include "/lib/atmosphere/volumetrics.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    color = texture(colortex0, texcoord);
    vec2 lightmap = texture(colortex1, texcoord).rg;
    float depth = texture(depthtex0, texcoord).r;

    vec4 SpecMap = texture(colortex3, texcoord);
    bool isMetal = SpecMap.g >= 230.0 / 255.0;
    vec3 surfNorm = texture(colortex4, texcoord).rgb;
    vec3 normal = normalize((surfNorm - 0.5) * 2.0);
    //space conversions
    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
    vec3 worldPos = feetPlayerPos + cameraPosition;
    vec4 waterMask = texture(colortex5, texcoord);
    int blockID = int(waterMask) + 100;
    bool isWater = blockID == WATER_ID;
    vec3 noise;
    for(int i = 0; i < 8; i++) {
        noise += blue_noise(floor(gl_FragCoord.xy), frameCounter, i);
    }
    vec3 shadowViewPos_start = (shadowModelView * vec4(vec3(0.0), 1.0)).xyz;
    vec4 shadowClipPos_start = shadowProjection * vec4(shadowViewPos_start, 1.0);

    vec3 shadowViewPos_end = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
    vec4 shadowClipPos_end = shadowProjection * vec4(shadowViewPos_end, 1.0);

    vec3 startPos = vec3(0.0,0.0,0.0);
    vec3 endPos = worldPos;
    vec3 fog = color.rgb;

   
  #ifdef VOLUMETRICS
  #ifndef ADVANCED_FOG_TRACING
  color.rgb += volumetricRaymarch(
    shadowClipPos_start,
    shadowClipPos_end,
    VL_SAMPLES,
    noise.x,
    feetPlayerPos,
    color.rgb,
    normal,
    lightmap
  );
  #endif
    const float UNIFORM_PHASE = 1.0 / (4.0 * PI);
    const float _StepSize = 7.35;
    const float _NoiseOffset = 2.05;
    const float MULTI_SCATTER_GAIN = 0.35;   // how much single scatter feeds MS
    const float MULTI_SCATTER_DECAY = 0.85;  // energy loss per step

    float phaseIncFactor = smoothstep(225, 0, eyeBrightnessSmooth.y);
    float scatterReduce = smoothstep(0, 185, eyeBrightnessSmooth.y);
    vec3 lightScattering = vec3(32.0);

    lightScattering = mix(lightScattering, lightScattering * 4, phaseIncFactor);
    vec3 entryPoint = cameraPosition;
    vec3 viewDir = worldPos - cameraPosition;
    float viewLength = length(viewDir);
    vec3 rayDir = normalize(viewDir);

    float distLimit = min(viewLength, 300.0);
    float distTravelled = noise.x * _NoiseOffset;

    float transmittance = 1;
    vec3 fogCol = computeSkyColoring(vec3(0.0));
    fogCol = mix(fogCol, fogCol * 0.4, wetness);
    vec3 shadowNormal = mat3(shadowModelView) * normal ;
    const float shadowMapPixelSize = 1.0 / float(SHADOW_RESOLUTION);

    vec3 biasAdjustFactor = vec3(
        shadowMapPixelSize * 1.0,
        shadowMapPixelSize * 1.0,
        -0.0003803515625);

    float sampleRadius = SHADOW_SOFTNESS * shadowMapPixelSize * 0.64;
    vec3 multiScatterEnergy = vec3(0.0);
    while(distTravelled < distLimit) {
        vec3 rayPos = entryPoint + rayDir * distTravelled;
        vec3 shadowRayPos = rayDir * distTravelled;
        float density = getCloudDensity(rayPos);
        if(density > 0)
        {
            vec4 shadowClip = getShadowClipPos(shadowRayPos);
            vec3 shadow = vec3(0.0);
            for (int s = 0; s < 3; s++) {
                vec2 offset = vogelDisc(s, 3, noise.x) * sampleRadius;
                vec4 offsetShadowClipPos = shadowClip + vec4(offset, 0.0, 0.0);
                offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
                vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
                vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
                shadow += getShadow(shadowScreenPos); // take shadow sample
            }
            shadow /= float(3);
            float fogHeight = smoothstep(155,0, rayPos.y);
            vec3 sunCol = currentSunColor(vec3(0.0));
             
            vec3 lightDir = worldLightVector;
            float phase =  CS(0.65, dot(rayDir, lightDir));
       
            float scatter = density * _StepSize * transmittance;

           float msFactor = clamp(1.0 - transmittance, 0.0, 1.0);
            float msPhase = mix(phase, UNIFORM_PHASE, msFactor);
             vec3 singleScatter =
            sunCol *
            lightScattering *
            phase *
            scatter *
            shadow;

         multiScatterEnergy +=
            singleScatter *
            MULTI_SCATTER_GAIN *
            density;

        // decay MS energy over distance
        multiScatterEnergy *= MULTI_SCATTER_DECAY;
        vec3 multiScatter =
            multiScatterEnergy *
            msPhase *
            scatter;

           
        // accumulate fog
        fogCol = mix(color.rgb, fogCol, scatterReduce);
        fogCol += singleScatter + multiScatter;

        transmittance *= exp(-density * _StepSize);
        }
            
    

    distTravelled += _StepSize;
}
    color.rgb = mix(color.rgb, fogCol, 1.0 - clamp(transmittance,0,1));
    #endif

   
}
