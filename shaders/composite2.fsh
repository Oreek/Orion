
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;  // Main color
uniform sampler2D colortex4;  // Bloom 1
uniform sampler2D colortex5;  // Bloom 2
uniform float viewWidth;
uniform float viewHeight;

const float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

/* RENDERTARGETS: 0,4 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outBloom;

vec3 gaussianBlurV(sampler2D tex, vec2 uv, vec2 texelSize, float scale) {
    vec3 result = texture(tex, uv).rgb * weights[0];

    for (int i = 1; i < 5; i++) {
        vec2 offset = vec2(0.0, float(i) * scale) * texelSize;
        result += texture(tex, uv + offset).rgb * weights[i];
        result += texture(tex, uv - offset).rgb * weights[i];
    }

    return result;
}

void main() {
    vec4 color = texture(colortex0, texcoord);
    vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
    
    #ifdef BLOOM_ENABLED

        vec3 bloom1 = gaussianBlurV(colortex4, texcoord, texelSize, 1.0);
        vec3 bloom2 = gaussianBlurV(colortex5, texcoord, texelSize * 2.0, 2.0);
        
        vec3 combinedBloom = bloom1 * 0.5 + bloom2 * 0.5;
        outBloom = vec4(combinedBloom, 1.0);
    
    #else

        outBloom = vec4(0.0);

    #endif

    outColor = color;
}