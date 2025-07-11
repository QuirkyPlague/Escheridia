#ifndef BLUR_GLSL
#define BLUR_GLSL

#include "/lib/SSR.glsl"
#include "/lib/util.glsl"
#include "/lib/uniforms.glsl"


vec3 blurTracing(vec3 endPos, vec3 origin, int stepCount, float jitter, float depth, out vec3 rayPosition) {

    vec3 stepSize = (origin - endPos) / stepCount;
    vec3 loopPos =  origin + jitter * stepSize;
    bool intersect = false;
    // Our intersection isn't found by default

   
    // We settle the ray's starting point and jitter it
    // Jittering reduces the banding caused by a low amount of steps, it's basically multiplying the direction by a random value (like noise)
    for(int i = 0; i <= stepCount && !intersect; i++) {

        
        // If the ray's depth is bigger than the geometry depth, then our ray has hit the geometry 
    }
    return rayPosition;
}

vec3 blur(vec3 feetPlayerPos, float depth)
{
    vec3 blurColor = vec3(0.0);
    vec3 origin = cameraPosition;
    vec3 worldPos = cameraPosition + feetPlayerPos;
    vec3 blurPos = vec3(0.0);
    float jitter = IGN(gl_FragCoord.xy, frameCounter * 16);
    float linearDepth = (2.0 * near * far) / (far+ near - (2.0 * depth - 1.0) * (far - near));
    blurTracing(worldPos, origin,16, jitter, depth, blurPos);

    float sampleRadius = 1.0;
    
	for(int i = 0; i < 16; i++)
   	{
      	vec2 offset = vogelDisc(i, 16 , jitter) * sampleRadius;
		vec3 offsetBlurPos = blurPos + vec3(offset, 0.0); // add offset
		blurPos = offsetBlurPos;
	}
    blurColor = blurPos;
    return blurColor;
}


#endif