#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blockID.glsl"



float remap(float value, float originalMin, float originalMax, float newMin, float newMax)
{
    return newMin + (((value - originalMin) / (originalMax - originalMin) * (newMax - newMin)));
}

/*
float lightmarch(vec3 origin, vec3 startPos, vec3 endPos)
{
    float darknessThreshold = 0.3;
     bool rayHitBox = boxIntersection(origin, worldLightVector,startPos, endPos);
     if(!rayHitBox) return 0.0;
     vec3 rayStep = (endPos - startPos) / float(64);
     float totalDensity = 0.0;

     for(int i = 0; i < 64; i ++)
     {
        startPos += worldLightVector * rayStep;
        totalDensity += max(0.0, sampleDensity(startPos) * float(rayStep));   
     }
     float transmittance = exp(-totalDensity * 0.6);
    return darknessThreshold + transmittance * (1-darknessThreshold);

}
*/

bool boxIntersection(in vec3 origin, in vec3 direction, out vec3 startPos, out vec3 endPos)
{   
    float upperCloudLayer = 1200 + 50;
    float lowerCloudLayer = 1200;

     float t1 = max((upperCloudLayer - origin.y) / direction.y, 0.0);
    float t2 = max((lowerCloudLayer - origin.y) / direction.y, 0.0);
  
    
    if (abs(t1) == - abs(t2)) return false;

    startPos = origin + min(t1, t2) * direction;
    endPos = origin + max(t1, t2) * direction;

    return true;
     
}

float sampleDensity(vec3 pos)
{
    float height = 0.0;
     #if CLOUD_STYLE == 0
     height=smoothstep(CLOUD_PLANE_BOTTOM,CLOUD_PLANE_TOP,pos.y);
    if(pos.y>CLOUD_PLANE_TOP + CLOUD_THICKNESS)return 0.;
     if(pos.y<CLOUD_PLANE_BOTTOM)return 0.;
    #else
    height = smoothstep(170, 210, pos.y);
    if(pos.y>180+ CLOUD_THICKNESS)return 0.;
     if(pos.y<171)return 0.;
    #endif

    vec4 shape = vec4(0.0);
    vec4 detail1 = vec4(0.0);
    vec4 detail2 = vec4(0.0);
    vec3 uvw = pos * CLOUD_NOISE_SCALE * 0.0001 + 1.0 * 0.1 * (frameTimeCounter * 0.003);
    #if CLOUD_STYLE == 0
    shape = texture(clouds, uvw.xz);
    #else
    shape = texture(cloudBase, uvw.xz);
    detail1 = texture(fogTex, uvw.xz);
    detail2 = texture(detail, uvw.xz);
    shape.r = remap(detail1.r, 1.0 - shape.r, 1.0, 0.0, 1.0) + remap(shape.r, 1.0 - detail2.r, 1.0, 0.0, 1.0);
    #endif

    float density = max(0, shape.r - CLOUD_DENSITY_THRESHOLD) * CLOUD_DENSITY;
    density *= height;
    #if CLOUD_STYLE ==1
    density *=7;
    #endif
    return density;
}




vec3 cloudRaymarch(vec3 worldPos,vec3 noise, vec3 color)
{
    const float uniformPhase= 1./(4.*PI);
    const float _StepSize=6.4;
    const float _NoiseOffset=5.65;
    const float MULTI_SCATTER_GAIN=53.79;
    const float MULTI_SCATTER_DECAY=.93;
    const float liningIntensity = 15.0;
    const float liningSpread = 1.1;
  
    vec3 lightScattering=vec3(2.34)*PHASE_MULTIPLIER;
    vec3 entryPoint=cameraPosition;
    vec3 viewDir=worldPos-cameraPosition;
    vec3 eyePos = viewDir - gbufferModelViewInverse[3].xyz;
    float viewLength=length(eyePos);
    vec3 rayDir=normalize(eyePos);
    
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
    vec3 fogCol=computeSkyColoring(vec3(0.)) * uniformPhase;
    vec3 absCoeff = vec3(1.0, 1.0, 1.0);
   //fog col is ambient sky color *NEEDS RENAMING*
    vec3 skyCol=computeSkyColoring(vec3(0.));
    vec3 sunCol=currentSunColor(vec3(0.));
    sunCol=pow(sunCol,vec3(2.2));
    fogCol=pow(fogCol,vec3(2.2));
     fogCol *= 155.5;
    vec3 multiScatterEnergy=vec3(0.);
    vec3 clouds=vec3(0.0);
    while(distTravelled<distLimit)
    {
        vec3 rayPos=entryPoint+rayDir*distTravelled;
        
        float density=sampleDensity(rayPos);
        if(density >0)
        {
            transmission *= exp(-absCoeff * density * _StepSize);
       //calculate phase
        vec3 lightDir=worldLightVector;
        float phase=  henyeyGreensteinPhase(dot(rayDir,lightDir), .9) + henyeyGreensteinPhase(dot(rayDir,lightDir), -.45);
       //currently unused
float silverLining = max(henyeyGreensteinPhase(dot(rayDir,lightDir), .65), liningIntensity * henyeyGreensteinPhase(dot(rayDir,lightDir), 0.99 - liningSpread));
       
        float scatter=density*_StepSize*transmittance;
        float energy = exp(-density) * phase;
        float msFactor=clamp(1.-transmittance,0.,1.);
        float msPhase=mix(energy,uniformPhase,msFactor);
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
        
       
        multiScatterEnergy*=MULTI_SCATTER_DECAY;
        vec3 multiScatter=
        multiScatterEnergy*
        msPhase*
        scatter *  mix(2.0 * powder, vec3(1.0), dot(rayDir, lightDir) * 0.5 + 0.5);

         vec3 sampleExtinction = ( fogCol + absCoeff);
        float sampleTransmittance = exp(-_StepSize * 1.0);
    
        vec3 totalInscatter=singleScatter+multiScatter;
        fogCol +=
      (totalInscatter - totalInscatter * sampleTransmittance) /
      sampleExtinction;
        transmission *= sampleTransmittance;

        transmittance*=exp(-density*_StepSize);
        }
        
        distTravelled+=_StepSize;
    }
    color=mix(color,fogCol + transmission,1.-clamp(transmittance,0,1));
    
    return color;
}

vec4 cloudMarching(vec3 position, float jitter)
{   
    //position is worldPos or calculated as feetPlayerPos + cameraPosition;

    const float CLOUD_STEPS = 12;
    vec3 entryPoint=cameraPosition;
    
    //technically feetPlayerPos
    vec3 viewDir=position-cameraPosition;
    vec3 direction = normalize(viewDir);

    float extinction = 0.0;
    vec3 scattering = vec3(0.0);
    vec3 stepSize = (position - entryPoint )  * (1.0 / CLOUD_STEPS);
    float rayLength = length(stepSize);
    vec3 stepLength =  (jitter) * stepSize;
    for(int i = 0; i < CLOUD_STEPS; i++)
    {   
        vec3 rayPos=entryPoint+direction + stepLength ;
        float density = sampleDensity(rayPos);
        if(density > 0)
        {
        float scatterCoeff = 1.0 * density;
        float extinctionCoeff = 1.0 * density;
        extinction *= (-extinctionCoeff * rayLength);
        vec3 sunColor = currentSunColor(vec3(0.0));
        vec3 ambientColor = computeSkyColoring(vec3(0.0));
        float ambientPhase = 1.0 / (4 * PI);
        float VdotL = dot(direction, worldLightVector);
        float phase = henyeyGreensteinPhase(VdotL, .65) ;
        vec3 stepScattering = scatterCoeff * rayLength * (phase * sunColor + ambientPhase * ambientColor);
        scattering += stepScattering;

        }
        
        
        
    }   
    return vec4(scattering, extinction);
}
#endif//CLOUDS_GLSL