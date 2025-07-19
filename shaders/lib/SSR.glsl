#ifndef SSR_GLSL
#define SSR_GLSL 

//taken fromn Blemu's training raytracer found at https://gist.github.com/BelmuTM/af0fe99ee5aab386b149a53775fe94a3
#define BINARY_REFINEMENT 1 //[0 1]
#define BINARY_COUNT 4
#define BINARY_DECREASE 0.5

const float handDepth = MC_HAND_DEPTH;

float getDepth(vec2 pos, sampler2D depthBuffer) {
  return texelFetch(depthBuffer, ivec2(pos * vec2(viewWidth, viewHeight)), 0).r;
}
vec3 diagonal(mat4 mat) { return vec3(mat[0].x, mat[1].y, mat[2].z);      }
vec3 projectionOrthogonal(mat4 mat, vec3 v) { return diagonal(mat) * v + mat[3].xyz;  }

vec3 viewToScreen(vec3 viewPos) {
	return (projectionOrthogonal(gbufferProjection, viewPos) / -viewPos.z) * 0.5 + 0.5;
}

// Takes the minimum of 3 values
float minOf(vec3 x) { return min(x.x, min(x.y, x.z)); }

void binarySearch(inout vec3 rayPosition, vec3 rayDirection) {
    for(int i = 0; i < BINARY_COUNT; i++) {
        rayPosition += sign(texture(depthtex0, rayPosition.xy).r - rayPosition.z) * rayDirection;
        // Going back and forth using the delta of the 2 different depths as a parameter for sign()
        rayDirection *= BINARY_DECREASE;
        // Decreasing the step length (to slowly tend towards the intersection)
    }
}

// The favorite raytracer of your favorite raytracer
bool raytrace(vec3 viewPosition, vec3 rayDirection, int stepCount, float jitter, out vec3 rayPosition) {
    // "out vec3 rayPosition" is our ray's position, we use it as an "out" parameter to be able to output both the intersection check and the hit position

    rayPosition  = viewToScreen(viewPosition);
    // Starting position in screen space, it's better to perform space conversions OUTSIDE of the loop to increase performance
    rayDirection  = viewToScreen(viewPosition + rayDirection) - rayPosition;
   
    rayDirection = normalize(rayDirection);
    rayDirection *= minOf((sign(rayDirection) - rayPosition) / rayDirection) * (1.0 / stepCount);
    // Calculating the ray's direction in screen space, we multiply it by a "step size" that depends on a few factors from the DDA algorithm

    bool intersect = false;
    // Our intersection isn't found by default

    rayPosition += rayDirection * jitter;
    // We settle the ray's starting point and jitter it
    // Jittering reduces the banding caused by a low amount of steps, it's basically multiplying the direction by a random value (like noise)
     
   
    for(int i = 0; i <= stepCount && !intersect; i++, rayPosition += rayDirection) 
    {
        // Loop until we reach the max amount of steps OR if an intersection is found, add 1 at each iteration AND march the ray (position += direction)
        // Checking if the ray goes outside of the screen (if clamping the coordinates to [0;1] returns a different value, then we're outside)
        // There's no need to continue ray marching if the ray goes outside of the screen
        if (clamp(rayPosition, 0 , 1) != rayPosition) return false; // we went offscreen
       float depth = texture(depthtex0, rayPosition.xy).r;
        // Sampling the depth at the ray's screen space position
	        intersect = rayPosition.z > depth && rayPosition.z > handDepth && depth < 1.0;
       if (intersect) {
      break;
    }
        // If the ray's depth is bigger than the geometry depth, then our ray has hit the geometry 
    }

    #if BINARY_REFINEMENT == 1
        binarySearch(rayPosition, rayDirection);
        // Binary search for some extra accuracy
    #endif

    return intersect;
    // Outputting the boolean
}

#endif //SSR_GLSL