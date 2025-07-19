#ifndef BRDF_GLSL
#define BRDF_GLSL


vec3 brdf(vec3 albedo, vec3 F0, vec3 L, vec3 currentSunlight,vec3 N, vec3 H,vec3 V, float roughness, vec4 SpecMap)
{
  vec3 Lo = vec3(0.0);
    
    // calculate per-light radiance
    float dist    = length(L);
    float attenuation = 15.0 * (dist * dist);
    vec3 radiance    = currentSunlight * attenuation ;  
    
      

    vec3 F  = fresnelSchlick(max(dot(H, V),0.0), F0);
        
    // cook-torrance brdf
    float NDF = DistributionGGX(N, H, roughness);       
    float G   = GeometrySmith(N, V, L, roughness); 

    vec3 numerator    = NDF * G * F;
    float denominator = 4.0 * clamp(dot(N, V), 0.0, 1.0) * clamp(dot(N, L), 0.0, 1.0)  + 0.0001;
    vec3 spec     = numerator / denominator;  
    vec3 kS = F;
        
    // add to outgoing radiance Lo
    float NdotL = clamp(dot(N, L), 0.0, 1.0);        
    Lo = spec * radiance * NdotL;
    
   
    vec3 speculars =   Lo;
    return speculars;
}

vec3 brdfFull(vec3 albedo, vec3 F0, vec3 L, vec3 currentSunlight,vec3 N, vec3 H,vec3 V, float roughness, vec4 SpecMap, vec3 diffuse, vec3 shadow)
{
  vec3 Lo = vec3(0.0);
        // calculate per-light radiance
        float dist    = length(L);
        float attenuation = 1.0 * (dist * dist);
        vec3 radiance    = diffuse * attenuation ;  

        vec3 F  = fresnelSchlick(max(dot(H, V),0.0), F0);
        
           // cook-torrance brdf
        float NDF = DistributionGGX(N, H, roughness);       
        float G   = GeometrySmith(N, V, L, roughness); 

        vec3 numerator    = NDF * G * F;
        float denominator = 4.0 * clamp(dot(N, V), 0.0, 1.0) * clamp(dot(N, L), 0.0, 1.0)  + 0.0001;
        vec3 spec     = numerator / denominator;  
        vec3 kS = F;
        vec3 kD = vec3(1.0, 1.0, 1.0) - kS;
      if(SpecMap.g >= 230.0/255.0)
      {
        kD *= 0.0;
      }

          // add to outgoing radiance Lo
      float NdotL = clamp(dot(N, L), 0.0, 1.0);        
      Lo = (kD  * albedo / PI + spec) * radiance * diffuse;

   return Lo;
}



#endif