#version 330 core
out vec4 FragColor;

in vec2 TexCoords;

uniform sampler2D screenTexture;

uniform bool posteffect;

void main()
{
	if (posteffect){
		FragColor = vec4(vec3(1.0 - texture(screenTexture, TexCoords)), 1.0);
	} else {
		FragColor = texture(screenTexture, TexCoords);
	}
} 