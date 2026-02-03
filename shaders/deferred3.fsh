#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blockID.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
    
     vec2 lightmap=texture(colortex1,texcoord).rg;
    float depth=texture(depthtex0,texcoord).r;
    
  
    
    vec4 SpecMap=texture(colortex3,texcoord);
    bool isMetal=SpecMap.g>=230./255.;
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
    vec3 noise;
    for(int i=0;i<STBN_SAMPLES;i++){
        noise+=blue_noise(floor(gl_FragCoord.xy),frameCounter,i);
    }

    
    vec3 startPos=vec3(0.,0.,0.);
    vec3 endPos=worldPos;
    vec3 fog=color.rgb;
    

    #ifdef CLOUDS

    const float UNIFORM_PHASE=1./(4.*PI);
    const float _StepSize= 6.0;
    const float _NoiseOffset=3.65;
    const float MULTI_SCATTER_GAIN= 0.9;// how much single scatter feeds MS
    const float MULTI_SCATTER_DECAY= 0.93;// energy loss per step
    
    float phaseIncFactor=smoothstep(225,0,eyeBrightnessSmooth.y);
    float scatterReduce=smoothstep(0,185,eyeBrightnessSmooth.y);
    vec3 lightScattering=vec3(1.14) * PHASE_MULTIPLIER;
    
  
    vec3 entryPoint=cameraPosition;
    vec3 viewDir=worldPos-cameraPosition;
    float viewLength=length(viewDir);
    vec3 rayDir=normalize(viewDir);
    
    float distLimit=min(viewLength,1500);
    float distTravelled=noise.x*_NoiseOffset;
    
    float transmittance=1;
    vec3 fogCol=computeSkyColoring(vec3(0.));
    vec3 sunCol=currentSunColor(vec3(0.));
    sunCol=pow(sunCol,vec3(2.2));
    fogCol=pow(fogCol,vec3(2.2));
    fogCol=mix(fogCol,fogCol*.4,wetness);
    vec3 shadowNormal=mat3(shadowModelView)*normal;
    const float shadowMapPixelSize=1./float(SHADOW_RESOLUTION);
    
    vec3 biasAdjustFactor=vec3(
        shadowMapPixelSize*1.,
        shadowMapPixelSize*1.,
    -.0003803515625);
    
    float sampleRadius=SHADOW_SOFTNESS*shadowMapPixelSize*.64;
    vec3 multiScatterEnergy=vec3(0.);
    while(distTravelled<distLimit){
        vec3 rayPos=entryPoint+rayDir*distTravelled;
       
        
        float density=getCloudDensity(rayPos);
        
  
        
            
            vec3 lightDir=worldLightVector;
            float phase= 9.25 * CS(.65,dot(rayDir,lightDir)) +  3.7 * CS(-.1,dot(rayDir,lightDir)) ;
            float scatter=density*_StepSize*transmittance;
            
            float msFactor=clamp(1.-transmittance,0.,1.);
            float msPhase=mix(phase,UNIFORM_PHASE,msFactor);
            vec3 singleScatter=
            sunCol*
            lightScattering*
            phase*
            scatter;
            
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
            
            // accumulate fog
          
            fogCol+=singleScatter+multiScatter;
            
            transmittance*=exp(-density*_StepSize);
        
        
        distTravelled+=_StepSize;
    }
    color.rgb=mix(color.rgb,fogCol,1.-clamp(transmittance,0,1));
    #endif
  
}
