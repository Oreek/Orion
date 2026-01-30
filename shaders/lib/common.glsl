
/* COMMON STUFF */

#ifndef COMMON_GLSL
#define COMMON_GLSL


// CONSTANTS
#define PI 3.14159265359
#define TAU 6.28318530718
#define EULER 2.71828182846
#define GOLDEN_RATIO 1.61803398875
#define EPSILON 0.0001


// BASIC FUNCTIONS

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

vec2 saturate(vec2 x) {
    return clamp(x,0.0,1.0);
}

vec3 saturate(vec3 x) {
    return clamp(x,0.0,1.0);
}

vec4 saturate(vec4 x) {
    return clamp(x,0.0,1.0);
}

float smin(float a, float b, float k) {
    float h = saturate(0.5 + 0.5 * (b - a) / k);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float linearStep(float edge0, float edge1, float x) {
    return saturate((x - edge0) / (edge1 - edge0));
}

float remap(float value, float inMin, float inMax, float outMin, float outMax) {
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin);
}


float getLuminance(vec3 color) {
    return dot(color, vec3(0.2126,0.7152,0.0722));
}

vec3 adjustSaturation(vec3 color, float saturation) {
    float luma = getLuminance(color);
    return mix(vec3(luma), color, saturation);
}

vec3 adjustContrast(vec3 color, float contrast) {
    return (color - 0.5) * contrast + 0.5;
}

vec3 linearToGamma(vec3 color) {
    return pow(color, vec3(1.0 / 2.2));
}

vec3 gammaToLinear(vec3 color) {
    return pow(color, vec3(2.2));
}


vec3 linearToSRGB(vec3 color) {
    return mix(
        color * 12.92,
        pow(color, vec3(1.0 / 2.4)) * 1.055 - 0.055,
        step(0.0031308, color)
    );
}

vec3 sRGBToLinear(vec3 color) {
    return mix(
        color / 12.92,
        pow((color + 0.055) / 1.055, vec3(2.4)),
        step(0.04045, color)
    );
}


// TONEMAPPING FUNCTIONS

vec3 tonemapReinhard(vec3 color) {
    return color / (color + 1.0);
}

vec3 tonemapReinhardExtended(vec3 color, float whitePoint) {
    vec3 numerator = color * (1.0 + color / (whitePoint * whitePoint));
    return numerator / (1.0 + color);
}

vec3 tonemapACES(vec3 color) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return saturate((color * (a * color + b)) / (color * (c * color + d) + e));
}

vec3 uncharted2Tonemap(vec3 x) {
    const float A = 0.15;
    const float B = 0.50;
    const float C = 0.10;
    const float D = 0.20;
    const float E = 0.02;
    const float F = 0.30;
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

vec3 tonemapUncharted2(vec3 color) {
    const float W = 11.2;
    vec3 curr = uncharted2Tonemap(color * 2.0);
    vec3 whiteScale = 1.0 / uncharted2Tonemap(vec3(W));
    return curr * whiteScale;
}


// NOISE FUNCTIONS

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float simplexNoise(vec2 p) {
    const float K1 = 0.366025404;
    const float K2 = 0.211324865;
    
    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    vec2 o = step(a.yx, a.xy);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;
    
    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a, hash22(i) - 0.5), dot(b, hash22(i + o) - 0.5), dot(c, hash22(i + 1.0) - 0.5));
    
    return dot(n, vec3(70.0));
}

float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * valueNoise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}


// SPACE CONVERSION

vec3 projectAndDivide(mat4 projMatrix, vec3 pos) {
    vec4 homPos = projMatrix * vec4(pos, 1.0);
    return homPos.xyz / homPos.w;
}

vec3 screenToView(vec2 texcoord, float depth, mat4 projInverse) {
    vec3 ndc = vec3(texcoord, depth) * 2.0 - 1.0;
    return projectAndDivide(projInverse, ndc);
}

vec3 viewToWorld(vec3 viewPos, mat4 viewInverse) {
    return (viewInverse * vec4(viewPos, 1.0)).xyz;
}

float linearizeDepth(float depth, float near, float far) {
    return (2.0 * near * far) / (far + near - (depth * 2.0 - 1.0) * (far - near));
}


// NORMAL ENCODING/DECODING

vec3 encodeNormal(vec3 normal) {
    return normal * 0.5 + 0.5;
}

vec3 decodeNormal(vec3 encodedNormal) {
    return encodedNormal * 2.0 - 1.0;
}

vec2 octEncode(vec3 n) {
    n /= abs(n.x) + abs(n.y) + abs(n.z);
    if (n.z < 0.0) {
        n.xy = (1.0 - abs(n.yx)) * sign(n.xy);
    }
    return n.xy * 0.5 + 0.5;
}

vec3 octDecode(vec2 f) {
    f = f * 2.0 - 1.0;
    vec3 n = vec3(f.xy, 1.0 - abs(f.x) - abs(f.y));
    float t = max(-n.z, 0.0);
    n.x += n.x >= 0.0 ? -t : t;
    n.y += n.y >= 0.0 ? -t : t;
    return normalize(n);
}


// DITHERING

float bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x / 2.0 + a.y * a.y * 0.75);
}

float bayer4(vec2 a) {
    return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

float bayer8(vec2 a) {
    return bayer4(0.5 * a) * 0.25 + bayer2(a);
}

float bayer16(vec2 a) {
    return bayer8(0.5 * a) * 0.25 + bayer2(a);
}

float interleavedGradientNoise(vec2 coord) {
    return fract(52.9829189 * fract(0.06711056 * coord.x + 0.00583715 * coord.y));
}


#endif