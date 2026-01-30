
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;  // Main color
uniform sampler2D colortex4;  // Bloom data
uniform float viewWidth;
uniform float viewHeight;

/* RENDERTARGETS: 0,4,5 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outBloom1;
layout(location = 2) out vec4 outBloom2;

void main() {
    vec4 color = texture(colortex0, texcoord);
    vec4 bloom = texture(colortex4, texcoord);
    
    #ifdef BLOOM_ENABLED

        vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);

        vec3 bloomSum = vec3(0.0);
        bloomSum += texture(colortex4, texcoord + vec2(-2.0,-2.0) * texelSize).rgb * 0.03125;
        bloomSum += texture(colortex4, texcoord + vec2(0.0,-2.0) * texelSize).rgb * 0.0625;
        bloomSum += texture(colortex4, texcoord + vec2(2.0,-2.0) * texelSize).rgb * 0.03125;
        bloomSum += texture(colortex4, texcoord + vec2(-2.0,0.0) * texelSize).rgb * 0.0625;
        bloomSum += texture(colortex4, texcoord + vec2(0.0,0.0) * texelSize).rgb * 0.125;
        bloomSum += texture(colortex4, texcoord + vec2(2.0,0.0) * texelSize).rgb * 0.0625;
        bloomSum += texture(colortex4, texcoord + vec2(-2.0,2.0) * texelSize).rgb * 0.03125;
        bloomSum += texture(colortex4, texcoord + vec2(0.0,2.0) * texelSize).rgb * 0.0625;
        bloomSum += texture(colortex4, texcoord + vec2(2.0,2.0) * texelSize).rgb * 0.03125;
        
        bloomSum += texture(colortex4, texcoord + vec2(-1.0,-1.0) * texelSize).rgb * 0.0625;
        bloomSum += texture(colortex4, texcoord + vec2(1.0,-1.0) * texelSize).rgb * 0.0625;
        bloomSum += texture(colortex4, texcoord + vec2(-1.0,1.0) * texelSize).rgb * 0.0625;
        bloomSum += texture(colortex4, texcoord + vec2(1.0,1.0) * texelSize).rgb * 0.0625;
        
        outBloom1 = vec4(bloomSum, 1.0);

        vec2 texelSize2 = texelSize * 2.0;
        vec3 bloom2Sum = vec3(0.0);
        bloom2Sum += texture(colortex4, texcoord + vec2(-2.0, -2.0) * texelSize2).rgb;
        bloom2Sum += texture(colortex4, texcoord + vec2( 2.0, -2.0) * texelSize2).rgb;
        bloom2Sum += texture(colortex4, texcoord + vec2(-2.0,  2.0) * texelSize2).rgb;
        bloom2Sum += texture(colortex4, texcoord + vec2( 2.0,  2.0) * texelSize2).rgb;
        bloom2Sum += texture(colortex4, texcoord).rgb * 2.0;
        bloom2Sum /= 6.0;

        outBloom2 = vec4(bloom2Sum,  1.0);
    
    #else
        outBloom1 = vec4(0.0);
        outBloom2 = vec4(0.0);
    
    #endif

    outColor = color;
}