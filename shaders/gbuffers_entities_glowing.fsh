
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;

uniform sampler2D gtexture;
uniform float alphaTestRef;
uniform vec4 entityColor;

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outLightmap;
layout(location = 3) out vec4 outSpecular;

void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;
    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
    
    if (color.a < alphaTestRef) {
        discard;
    }
    
    vec3 normalOut = normalize(normal);
    
    outColor = vec4(color.rgb * 2.0, 1.0);
    outNormal = vec4(encodeNormal(normalOut), 1.0);
    outLightmap = vec4(1.0, 1.0, 0.0, 1.0);
    outSpecular = vec4(0.8, 0.0, 1.0, 1.0);
}
