#ifndef BLOCKID_GLSL
#define BLOCKID_GLSL

#define WATER_ID 101
#define TRANSLUCENT_ID 103
#define SSS_ID 104
#define METAL_ID 105


#ifdef DISTANT_HORIZONS
int dhConvert(int blockID)
{
    switch (blockID)
    {
          case DH_BLOCK_WATER:
        return WATER_ID;
    }
      return 0;
}
    #endif

#endif //BLOCKID_GLSL