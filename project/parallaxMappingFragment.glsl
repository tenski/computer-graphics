#version 330 core
out vec4 FragColor;

in VS_OUT {
    vec3 FragPos;
    vec2 TexCoords;
    vec3 TangentLightPos;
    vec3 TangentViewPos;
    vec3 TangentFragPos;
} fs_in;


uniform sampler2D diffuseMap;
uniform sampler2D normalMap;
uniform sampler2D depthMap;
uniform vec3 lightPos;
uniform vec3 viewPos;
uniform float heightScale;
uniform bool blinn;

vec2 ParallaxMapping(vec2 texCoords, vec3 viewDir){
    float height =  texture(depthMap, texCoords).r;     
    return texCoords - viewDir.xy * (height * heightScale);  
}

vec2 reliefPM(vec2 inTexCoords, vec3 inViewDir) { //, out float lastDepthValue) {
	const float _minLayers = 16.0;
	const float _maxLayers = 128.0;
	float _numLayers = mix(_maxLayers, _minLayers, abs(dot(vec3(0.0, 0.0, 1.0), inViewDir)));

	float deltaDepth = 1.0/_numLayers;
	vec2 deltaTexcoord = heightScale * inViewDir.xy/(inViewDir.z * _numLayers);

	vec2 currentTexCoords = inTexCoords;
	float currentLayerDepth = 0.0;
	
    	float currentDepthValue = texture(depthMap, currentTexCoords).r;
	while (currentDepthValue > currentLayerDepth) {
		currentLayerDepth += deltaDepth;
		currentTexCoords -= deltaTexcoord;
		currentDepthValue = texture(depthMap, currentTexCoords).r;

	}
// ======
// Relief PM 
// ======

// уполовиниваем смещение текстурных координат и размер слоя глубины
	deltaTexcoord *= 0.5;
	deltaDepth *= 0.5;
// сместимся в обратном направлении от точки, найденной в Steep PM
	currentTexCoords += deltaTexcoord;
	currentLayerDepth -= deltaDepth;

// установим максимум итераций поиска…
	const int _reliefSteps = 15;
	int currentStep = _reliefSteps;
	while (currentStep > 0) {
		currentDepthValue = texture(depthMap, currentTexCoords).r;
		deltaTexcoord *= 0.5;
		deltaDepth *= 0.5;
// если выборка глубины больше текущей глубины слоя, 
// то уходим в левую половину интервала
		if (currentDepthValue > currentLayerDepth) {
			currentTexCoords -= deltaTexcoord;
			currentLayerDepth += deltaDepth;
		}
// иначе уходим в правую половину интервала
		else {
			currentTexCoords += deltaTexcoord;
			currentLayerDepth -= deltaDepth;
		}
		currentStep--;
	}

//	lastDepthValue = currentDepthValue;
	return currentTexCoords;
}

void main()
{   
	// offset texture coordinates with Parallax Mapping
    vec3 viewDir = normalize(fs_in.TangentViewPos - fs_in.TangentFragPos);
    vec2 texCoords = fs_in.TexCoords;

	texCoords = reliefPM(fs_in.TexCoords, viewDir);      
    if (texCoords.x > 1.0 || texCoords.y > 1.0 || texCoords.x < 0.0 || texCoords.y < 0.0) discard;

	// obtain normal from normal map in range [0,1]
    vec3 normal = texture(normalMap, texCoords).rgb;
    // transform normal vector to range [-1,1]
    normal = normalize(normal * 2.0 - 1.0);  // this normal is in tangent space

    // get diffuse color
    vec3 color = texture(diffuseMap, texCoords).rgb;

    // ambient
    vec3 ambient = 0.1 * color;

    // diffuse
    vec3 lightDir = normalize(fs_in.TangentLightPos - fs_in.TangentFragPos);
    float diff = max(dot(lightDir, normal), 0.0);
    vec3 diffuse = diff * color;

    // specular
    float spec = 0.0;
    vec3 reflectDir = reflect(-lightDir, normal);
    spec = pow(max(dot(viewDir, reflectDir), 0.0), 8.0);

    vec3 specular = vec3(0.2) * spec;
    FragColor = vec4(ambient + diffuse + specular, 1.0);
}