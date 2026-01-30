
#version 330 compatibility

#include "/lib/settings.glsl"

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 viewPos;

uniform mat4 gbufferModelViewInverse;

void main() {
    gl_Position = ftransform();
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmcoord = (lmcoord * 33.05 / 32.0) - (1.05 / 32.0);
    
    glcolor = gl_Color;
    
    normal = normalize(gl_NormalMatrix * gl_Normal);
    normal = mat3(gbufferModelViewInverse) * normal;
    
    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
}
