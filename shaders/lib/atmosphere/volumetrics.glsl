#ifndef VOLUMETRICS_GLSL
#define VOLUMETRICS_GLSL






bool VolumetricLighting(vec3 viewPosition, vec3 rayDirection, int stepCount, float jitter, out vec3 rayPosition) {
    // "out vec3 rayPosition" is our ray's position, we use it as an "out" parameter to be able to output both the intersection check and the hit position

    // Calculating the ray's direction in screen space, we multiply it by a "step size" that depends on a few factors from the DDA algorithm

    bool intersect = false;
    // Our intersection isn't found by default

    rayPosition += rayDirection * jitter;
    // We settle the ray's starting point and jitter it
    // Jittering reduces the banding caused by a low amount of steps, it's basically multiplying the direction by a random value (like noise)
    for(int i = 0; i <= stepCount && !intersect; i++, rayPosition += rayDirection) {
        // Loop until we reach the max amount of steps OR if an intersection is found, add 1 at each iteration AND march the ray (position += direction)

        if(clamp(rayPosition.xy, 0, 1) != rayPosition.xy) false;
        // Checking if the ray goes outside of the screen (if clamping the coordinates to [0;1] returns a different value, then we're outside)
        // There's no need to continue ray marching if the ray goes outside of the screen

        float depth = texture(depthtex0, rayPosition.xy).r;
        // Sampling the depth at the ray's screen space position
      
        intersect = rayPosition.z > depth;
       
        
        // If the ray's depth is bigger than the geometry depth, then our ray has hit the geometry 
    }

    #if BINARY_REFINEMENT == 1
        binarySearch(rayPosition, rayDirection);
        // Binary search for some extra accuracy
    #endif

    return intersect;
    // Outputting the boolean
}

#endif