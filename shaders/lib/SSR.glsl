#ifndef SSR_GLSL
#define SSR_GLSL

//taken fromn Blemu's training raytracer found at https://gist.github.com/BelmuTM/af0fe99ee5aab386b149a53775fe94a3
#define BINARY_REFINEMENT 1 //[0 1]
#define BINARY_COUNT 4 //[2 4 6 8 10 12 14 16 18 20 22 24 28 32 36 40]
#define BINARY_DECREASE 0.5
uint binarySteps = uint(BINARY_COUNT);

const float handDepth = MC_HAND_DEPTH * 0.5 + 0.5;

float getDepth(vec2 pos, sampler2D depthBuffer) {
  return texelFetch(depthBuffer, ivec2(pos * vec2(viewWidth, viewHeight)), 0).r;
}

vec3 diagonal(mat4 mat) {
  return vec3(mat[0].x, mat[1].y, mat[2].z);
}
vec3 projectionOrthogonal(mat4 mat, vec3 v) {
  return diagonal(mat) * v + mat[3].xyz;
}

vec3 viewToScreen(vec3 viewPos) {
  return projectionOrthogonal(gbufferProjection, viewPos) / -viewPos.z * 0.5 +
  0.5;
}

// Takes the minimum of 3 values
float minOf(vec3 x) {
  return min(x.x, min(x.y, x.z));
}

float minOf(vec2 x) {
  return min(x.x, x.y);
}

void binarySearch(inout vec3 rayPosition, vec3 rayDirection) {
  for (int i = 0; i < BINARY_COUNT; i++) {
    rayPosition +=
      sign(
        texelFetch(
          depthtex0,
          ivec2(rayPosition.xy * vec2(viewWidth, viewHeight)),
          0
        ).r -
          rayPosition.z
      ) *
      rayDirection;
    // Going back and forth using the delta of the 2 different depths as a parameter for sign()
    rayDirection *= BINARY_DECREASE;
    // Decreasing the step length (to slowly tend towards the intersection)
  }
}

// The favorite raytracer of your favorite raytracer
bool raytrace(
  vec3 viewPosition,
  vec3 rayDirection,
  int stepCount,
  float jitter,
  out vec3 rayPosition
) {
  if (rayDirection.z > 0.0 && rayDirection.z >= -viewPosition.z) {
    return false;
  }

  rayPosition = viewToScreen(viewPosition);

  rayDirection = viewToScreen(viewPosition + rayDirection) - rayPosition;

  rayDirection = normalize(rayDirection);
  rayDirection *=
    minOf(
      abs(sign(rayDirection) - rayPosition) / max(abs(rayDirection), 0.00001)
    ) *
    (1.0 / stepCount);

  float depthLenience = max(
    abs(rayDirection.z) * 1.0,
    0.02 / (viewPosition.z * viewPosition.z)
  ); // From Dr Desten
  bool intersect = false;

  rayPosition += rayDirection * jitter;

  vec3 hitPosition;
  bool outOfBounds = false;
  for (int i = 0; i < stepCount; i++) {
    if (clamp(rayPosition, 0, 1) != rayPosition) {
      outOfBounds = true;
      break;
    }
    rayPosition += rayDirection;

    float depth = texelFetch(
      depthtex0,
      ivec2(rayPosition.xy * vec2(viewWidth, viewHeight)),
      0
    ).r;

    if (
      rayPosition.z > depth &&
      abs(depthLenience - (rayPosition.z - depth)) < depthLenience &&
      rayPosition.z > handDepth &&
      depth < 1.0
    ) {
      intersect = true;

    } else {
      intersect = false;

    }

    if (intersect) {
      break;
    }

  }

  if (outOfBounds) return false;
  #if BINARY_REFINEMENT == 1
  binarySearch(rayPosition, rayDirection);
  #endif

  return intersect;

}

#endif //SSR_GLSL
