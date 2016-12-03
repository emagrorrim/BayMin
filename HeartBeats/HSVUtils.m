//
//  Copyright © 2016 Christian Roman. All rights reserved.
//

#import "HSVUtils.h"

@implementation HSVUtils

float lowPassValue(size_t height, size_t width, uint8_t *buf, size_t bytesPerRow) {

  float r = 0, g = 0,b = 0;
  for(int y = 0; y < height; y++) {
    for(int x = 0; x < width * 4; x += 4) {
      b += buf[x];
      g += buf[x+1];
      r += buf[x+2];
    }
    buf += bytesPerRow;
  }
  r /= 255 * (float)(width * height);
  g /= 255 * (float)(width * height);
  b /= 255 * (float)(width * height);
  
  float h,s,v;
  RGBtoHSV(r, g, b, &h, &s, &v);
  static float lastH = 0;
  float highPassValue = h - lastH;
  lastH = h;
  float lastHighPassValue = 0;
  float lowPassValue = (lastHighPassValue + highPassValue) / 2;
  lastHighPassValue = highPassValue;
  
  return lowPassValue;
}

void RGBtoHSV(float r, float g, float b, float *h, float *s, float *v) {
  float min, max, delta;
  min = MIN(r, MIN(g, b));
  max = MAX(r, MAX(g, b));
  *v = max;
  delta = max - min;
  if(max != 0)
    *s = delta / max;
  else {
    *s = 0;
    *h = -1;
    return;
  }
  if(r == max) {
    *h = (g - b) / delta;
  } else if(g == max) {
    *h = 2 + (b - r) / delta;
  } else {
    *h = 4 + (r - g) / delta;
  }
  *h *= 60;
  if(*h < 0) {
    *h += 360;
  }
}

@end
