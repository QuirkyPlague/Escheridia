#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blockID.glsl"
#include "/lib/atmosphere/volumetrics.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0,13 */
layout(location=0)out vec4 color;
layout(location = 1) out vec4 history;
void main(){
    color=texture(colortex0,texcoord);
    vec2 lightmap=texture(colortex1,texcoord).rg;
    float depth=texture(depthtex0,texcoord).r;
    
    
   
    vec3 surfNorm=texture(colortex4,texcoord).rgb;
    vec3 normal=normalize((surfNorm-.5)*2.);
    //space conversions
    vec3 NDCPos=vec3(texcoord.xy,depth)*2.-1.;
    vec3 viewPos=projectAndDivide(gbufferProjectionInverse,NDCPos);
    vec3 feetPlayerPos=(gbufferModelViewInverse*vec4(viewPos,1.)).xyz;
    vec3 eyePlayerPos=feetPlayerPos-gbufferModelViewInverse[3].xyz;
    vec3 worldPos=feetPlayerPos+cameraPosition;
    vec4 waterMask=texture(colortex5,texcoord);
    int blockID=int(waterMask)+100;
    bool isWater=blockID==WATER_ID;

    vec3 noise= blue_noise(floor(gl_FragCoord.xy),frameCounter,STBN_SAMPLES);
    
    vec3 shadowViewPos_start=(shadowModelView*vec4(vec3(0.),1.)).xyz;
    vec4 shadowClipPos_start=shadowProjection*vec4(shadowViewPos_start,1.);
    
    vec3 shadowViewPos_end=(shadowModelView*vec4(feetPlayerPos,1.)).xyz;
    vec4 shadowClipPos_end=shadowProjection*vec4(shadowViewPos_end,1.);
  
    #ifdef VOLUMETRICS
    #ifndef ADVANCED_FOG_TRACING
    color.rgb+=volumetricRaymarch(
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
    #ifdef ADVANCED_FOG_TRACING
    
    float t=fract(worldTime/24000.);
    const int keys=7;
    const float keyFrames[keys]=float[keys](
        0.,//sunrise
        .0417,//day
        .45,//noon
        .5192,//sunset
        .5417,//night
        .9527,//midnight
        1.0//sunrise
    );
    
    const float morningFogPhase=MORNING_PHASE;
    const float dayFogPhase=DAY_PHASE;
    const float noonFogPhase=NOON_PHASE;
    const float eveningFogPhase=EVENING_PHASE;
    const float nightFogPhase=NIGHT_PHASE;
    
    const float fogPhase[keys]=float[keys](
        morningFogPhase,
        dayFogPhase,
        noonFogPhase,
        eveningFogPhase,
        nightFogPhase,
        nightFogPhase,
        morningFogPhase
    );
    const float intensity[keys]=float[keys](
        0.65,
        1.0,
        1.0,
        0.65,
        0.35,
        0.35,
        0.65
    );
    
    int i=0;
    //assings the keyframes
    for(int k=0;k<keys-1;++k){
        i+=int(step(keyFrames[k+1],t));
    }
    i=clamp(i,0,keys-2);
    
    //Interpolation factor based on the time
    float timeInterp=
    (t-keyFrames[i])/max(1e-6,keyFrames[i+1]-keyFrames[i]);
    timeInterp=smoothstep(0.,1.,timeInterp);
    
    float phaseVal=mix(fogPhase[i],fogPhase[i+1],timeInterp);
     float skyIntensity=mix(intensity[i],intensity[i+1],timeInterp);
    const float UNIFORM_PHASE=1./(4.*PI);
    const float _StepSize= STEP_SIZE;
    const float _NoiseOffset=16.05;
    const float MULTI_SCATTER_GAIN= MS_POWER;// how much single scatter feeds MS
    const float MULTI_SCATTER_DECAY= MS_FALLOFF;// energy loss per step
    
    float phaseIncFactor=smoothstep(225,0,eyeBrightnessSmooth.y);
    float scatterReduce=smoothstep(0,185,eyeBrightnessSmooth.y);
    vec3 lightScattering=vec3(4.) * PHASE_MULTIPLIER;
    
    lightScattering=mix(lightScattering,lightScattering*4,phaseIncFactor);
    
    vec3 entryPoint=cameraPosition;
    vec3 viewDir=worldPos-cameraPosition;
    float viewLength=length(viewDir);
    vec3 rayDir=normalize(viewDir);
    float farPlane=far*4.;
    float distLimit=min(viewLength,TRACING_DISTANCE);
    float distTravelled=noise.x*_NoiseOffset;
     vec3 absCoeff = vec3(0.5686, 0.5686, 0.5686);

    float transmittance= 1.0;
    vec3 transmission = vec3(1.0);
     float rayleigh = Rayleigh(dot(rayDir, worldLightVector));
    vec3 jungleCol = vec3(0.5373, 0.8196, 0.7451)  / (4 * PI);
    
 
    
    vec3 jungleTint = vec3(0.7412, 0.9333, 0.702) ;
    vec3 fogCol=computeSkyColoring(vec3(0.))  / (4 * PI);
    
    vec3 sunCol=currentSunColor(vec3(0.));
    sunCol = mix(sunCol, sunCol * jungleTint, jungleSmooth);
    
    fogCol = mix(fogCol, jungleCol * skyIntensity, jungleSmooth);
    sunCol=pow(sunCol,vec3(2.2));
    fogCol=pow(fogCol,vec3(2.2));
    fogCol=mix(fogCol,fogCol*.8,wetness);
    jungleCol *= 195;
    fogCol *= 195;
    
    vec3 shadowNormal=mat3(shadowModelView)*normal;
    const float shadowMapPixelSize=1./float(SHADOW_RESOLUTION);
    
    vec3 biasAdjustFactor=vec3(
        shadowMapPixelSize*1.,
        shadowMapPixelSize*1.,
    -.0003803515625);
    
    float sampleRadius=SHADOW_SOFTNESS*shadowMapPixelSize*.34;
    vec3 multiScatterEnergy=vec3(0.);
    while(distTravelled<distLimit){
        vec3 rayPos=entryPoint+rayDir*distTravelled;
        float height=smoothstep(143,64,rayPos.y);
        vec3 shadowRayPos=rayDir*distTravelled;
        float density=getFogDensity(rayPos);
        if(density>0)
        {
            vec4 shadowClip=getShadowClipPos(shadowRayPos);
            vec3 shadow=vec3(0.);
            for(int s=0;s<3;s++){
                vec2 offset=vogelDisc(s,3,noise.x)*sampleRadius;
                vec4 offsetShadowClipPos=shadowClip+vec4(offset,0.,0.);
                offsetShadowClipPos.xyz=distortShadowClipPos(offsetShadowClipPos.xyz);// apply distortion
                vec3 shadowNDCPos=offsetShadowClipPos.xyz/offsetShadowClipPos.w;// convert to NDC space
                vec3 shadowScreenPos=shadowNDCPos*.5+.5;// convert to screen space
                shadow+=getShadow(shadowScreenPos);// take shadow sample
            }
            shadow/=float(3);
            
            transmission *= exp(-absCoeff * _StepSize);
            vec3 lightDir=worldLightVector;
            float phase=CS(phaseVal,dot(rayDir,lightDir)) + 0.13 * CS(-0.1,dot(rayDir,lightDir));
            float scatter=density*_StepSize* float(transmittance);
            
            float msFactor=clamp(1.-float(transmittance),0.,1.);
            float msPhase=mix(phase,UNIFORM_PHASE,msFactor);
            vec3 singleScatter=
            sunCol*
            lightScattering*
            phase*
            scatter*
            shadow;
            
            multiScatterEnergy+=
            singleScatter*
            MULTI_SCATTER_GAIN*
            density;
            
            // decay MS energy over distance
            multiScatterEnergy*=MULTI_SCATTER_DECAY;
            vec3 multiScatter=
            multiScatterEnergy*
            msPhase*
            scatter;
            vec3 sampleExtinction = ( multiScatter + absCoeff);
            float sampleTransmittance = exp(-_StepSize * 1.0);
            // accumulate fog
            
            fogCol=mix(color.rgb,fogCol,scatterReduce);
            vec3 totalInscatter = singleScatter + multiScatter ;

    fogCol +=
      (totalInscatter - totalInscatter * sampleTransmittance) /
      sampleExtinction;
        transmission *= sampleTransmittance;
            
            transmittance*=exp(-density*_StepSize);
        }
        
        distTravelled+=_StepSize;
    }
   
    #if TEMPORAL_REPROJECTION == 1
    {
        float depth = texture(depthtex0, texcoord).r;
        // skip reprojecting sky/hand
        const float handDepth = MC_HAND_DEPTH * 0.5 + 0.5;
        if (depth > handDepth) {
            //gather reprojection coords
            vec3 screenPos = vec3(texcoord.xy, depth);
            vec3 NDCPos = screenPos * 2.0 - 1.0;
            vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
            vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
            feetPlayerPos += cameraPosition;
            feetPlayerPos -= previousCameraPosition;
            vec3 previousView = (gbufferPreviousModelView * vec4(feetPlayerPos, 1.0)).xyz;
            vec4 previousClip = gbufferPreviousProjection * vec4(previousView, 1.0);
            vec3 previousScreen = (previousClip.xyz / previousClip.w) * 0.5 + 0.5;
            vec2 prevCoord = previousScreen.xy;

            // rejection checks
            bool historyRejection = clamp(prevCoord, 0, 1) != prevCoord;
            float previousDepth = texture(depthtex0, prevCoord).r;
            float currentViewDepth = viewPos.z;
            float prevViewZ = projectAndDivide(gbufferProjectionInverse, vec3(prevCoord, previousDepth) * 2.0 - 1.0).z;
            float depthDelta = abs(currentViewDepth - prevViewZ);
            float depthThreshold = max(0.01, abs(currentViewDepth) * 0.01);
            float depthConfidence = clamp(1.0 - depthDelta / depthThreshold, 0, 1);
    
            vec4 historyColor = texture(colortex13, prevCoord) ;
            
            float historyWeight = 0.85 * float(!historyRejection);
            
            fogCol = mix(fogCol, historyColor.rgb, historyWeight);
            if (any(isnan(fogCol))) fogCol = vec3(0.0);
        }
    }
    #endif
     color.rgb=mix(color.rgb,fogCol,1.-clamp(transmittance,0,1));
    //color += traceFog(worldPos, color.rgb);
    #endif
    #endif

    

    // write history buffer (colortex13) for next frame
    history = vec4(fogCol,1.0);
}

