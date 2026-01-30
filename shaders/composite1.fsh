
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;  // Main color
uniform sampler2D colortex4;  // Bloom 1
uniform sampler2D colortex5;  // Bloom 2
uniform float viewWidth;
uniform float viewHeight;

const float weights[5] = float[](0.227027,0.1945946,0.1216216,0.054054,0.016216);

/* RENDERTARGETS: 0,4,5 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outBloom1;
layout(location = 2) out vec4 outBloom2;

vec3 gaussianBlurH(sampler2D tex, vec2 uv, vec2 texelSize, float scale) {
    vec3 result = texture(tex, uv).rgb * weights[0];

    for (int i = 1; i < 5; i++) {
        vec2 offset = vec2(float(i) * scale, 0.0) * texelSize;
        result += texture(tex, uv + offset).rgb * weights[i];
        result += texture(tex, uv - offset).rgb * weights[i];
    }

    return result;
}

void main() {
    vec4 color = texture(colortex0, texcoord);
    vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);

    #ifdef BLOOM_ENABLED

        vec3 bloom1 = gaussianBlurH(colortex4, texcoord, texelSize, 1.0);
        vec3 bloom2 = gaussianBlurH(colortex5, texcoord, texelSize * 2.0, 2.0);

        outBloom1 = vec4(bloom1, 1.0);
        outBloom2 = vec4(bloom2, 1.0);

    #else

        outBloom1 = vec4(0.0);
        outBloom2 = vec4(0.0);

    #endif

    outColor = color;
}