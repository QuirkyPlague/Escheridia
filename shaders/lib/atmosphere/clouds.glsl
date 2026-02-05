#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blockID.glsl"

float remap(float value, float originalMin, float originalMax, float newMin, float newMax)
{
    return newMin + (((value - originalMin) / (originalMax - originalMin) * (newMax - newMin)));
}

float cloudPhase(float cosTheta, float eccentricity)
{
    return ((1.0 - eccentricity * eccentricity)/ pow((1.0 + eccentricity * eccentricity - 2.0 * cosTheta),3.0 /2.0)) / 4 * PI;
}

float getCloudDensity(vec3 pos){
    float TOTAL_DENSITY = 65.84;

   
    const float _DensityThreshold2=CLOUD_DENSITY_THRESHOLD;
    float cloudDensity=0.;
    float weight=0.;
    
    vec3 cloudPos=pos;
    float height = 0.0;

    #if CLOUD_STYLE == 0
    height=smoothstep(CLOUD_PLANE_BOTTOM,CLOUD_PLANE_TOP,cloudPos.y);
    if(cloudPos.y>CLOUD_PLANE_TOP + CLOUD_THICKNESS)return 0.;
     if(cloudPos.y<CLOUD_PLANE_BOTTOM)return 0.;
    #else
    height = smoothstep(171,210, cloudPos.y);
    if(cloudPos.y>180+ CLOUD_THICKNESS)return 0.;
     if(cloudPos.y<171)return 0.;
    #endif

   

    cloudPos=cloudPos/10000*CLOUD_NOISE_SCALE;
    
    for(int i=0;i<4;i++){
        float sampleWeight=exp2(-float(i));
        cloudPos.xyz+=frameTimeCounter*.000014*sqrt(i+1);
        vec2 cloudSamplePos=(cloudPos.xz*exp2(float(i)));
        float cloudNoise = 0.0;
        #if CLOUD_STYLE == 0
         cloudNoise = texture(clouds,fract(cloudSamplePos)).r*sampleWeight;
         cloudDensity=dot(cloudNoise,cloudNoise);
         cloudDensity*=TOTAL_DENSITY;
        #else   
        cloudNoise = texture(cloudBase,fract(cloudSamplePos)).r*sampleWeight;
        float detailNoise = texture(detail,fract(cloudSamplePos)).r*sampleWeight;
        float detailNoise2 = texture(fogTex,fract(cloudSamplePos)).r*sampleWeight;
        cloudNoise = remap(detailNoise2, 1.0 - cloudNoise, 0.1, 0.0, 0.7);
        cloudDensity=cloudNoise;
        
        cloudDensity=clamp(cloudDensity-_DensityThreshold2,0,1)*TOTAL_DENSITY;
        #endif
        weight+=sampleWeight;
    }
    
    cloudDensity/=weight;
    
    cloudDensity*=1.*CLOUD_DENSITY;
 
    cloudDensity*=height;
    return cloudDensity;
}

vec3 cloudRaymarch(vec3 worldPos,vec3 noise, vec3 color)
{
    
    const float UNIFORM_PHASE=1./(4.*PI);
    const float _StepSize=4.4;
    const float _NoiseOffset=5.65;
    const float MULTI_SCATTER_GAIN=161.29;// how much single scatter feeds MS
    const float MULTI_SCATTER_DECAY=.93;// energy loss per step
    
  
    vec3 lightScattering=vec3(7.34)*PHASE_MULTIPLIER;
    vec3 entryPoint=cameraPosition;
    vec3 viewDir=worldPos-cameraPosition;
    float viewLength=length(viewDir);
    vec3 rayDir=normalize(viewDir);
    
    float farPlane=far*4.;
    float distLimit=0.;
    
    #if CLOUD_DISTANCE_TYPE==1
    distLimit=min(viewLength,farPlane);
    #else
    distLimit=min(viewLength,CLOUD_DISTANCE);
    #endif
    
    float distTravelled=noise.x*_NoiseOffset;
    
    float transmittance=1;
    vec3 transmission = vec3(1.0);
    vec3 fogCol=computeSkyColoring(vec3(0.)) / (4 * PI);
    vec3 absCoeff = vec3(1.0, 1.0, 1.0);
   
    vec3 skyCol=computeSkyColoring(vec3(0.));
    vec3 sunCol=currentSunColor(vec3(0.));
    sunCol=pow(sunCol,vec3(2.2));
    fogCol=pow(fogCol,vec3(2.2));
     fogCol *= 165.5;
    vec3 multiScatterEnergy=vec3(0.);
    vec3 clouds=vec3(0.0);
    while(distTravelled<distLimit){
        vec3 rayPos=entryPoint+rayDir*distTravelled;
        
        float density=getCloudDensity(rayPos);
        transmission *= exp(-absCoeff * viewLength);
       
        vec3 lightDir=worldLightVector;
        float phase=  henyeyGreensteinPhase(dot(rayDir,lightDir), .9) + henyeyGreensteinPhase(dot(rayDir,lightDir), -.45);
        float scatter=density*_StepSize*transmittance;
        float energy = exp(-density) * phase;
        float msFactor=clamp(1.-transmittance,0.,1.);
        float msPhase=mix(energy,UNIFORM_PHASE,msFactor);
        vec3 powder =
      clamp(1.0 - exp(-density * 2 * vec3(1.0)),0,1);
        vec3 singleScatter=
        sunCol*
        lightScattering*
        energy*
        scatter ;
    
        multiScatterEnergy+=
        singleScatter*
        MULTI_SCATTER_GAIN*
        density;
        
        // decay MS energy over distance
        multiScatterEnergy*=MULTI_SCATTER_DECAY;
        vec3 multiScatter=
        multiScatterEnergy*
        msPhase*
        scatter *  mix(2.0 * powder, vec3(1.0), dot(rayDir, lightDir) * 0.5 + 0.5);

         vec3 sampleExtinction = ( fogCol + absCoeff);
        float sampleTransmittance = exp(-viewLength * 1.0);
        // accumulate fog
         
           
        
        vec3 totalInscatter=singleScatter+multiScatter;
        fogCol +=
      (totalInscatter - totalInscatter * sampleTransmittance) /
      sampleExtinction;
        transmission *= sampleTransmittance;
            
            
        
        transmittance*=exp(-density*_StepSize);
        
        distTravelled+=_StepSize;
    }
    color=mix(color,fogCol + transmission,1.-clamp(transmittance,0,1));
    return color;
}

#endif//CLOUDS_GLSL