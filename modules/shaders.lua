brightnessShader = love.graphics.newShader([[
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
	{
			vec4 texcolor = Texel(texture, texture_coords) * color;
			texcolor.rgb = min(texcolor.rgb + vec3(0.2), vec3(1.0));
			return texcolor;
	}
]])

darknessShader = love.graphics.newShader([[
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
	{
		vec4 texcolor = Texel(texture, texture_coords) * color;
		texcolor.rgb = max(texcolor.rgb - vec3(0.1, 0.3, 0.3), vec3(0.0));
		return texcolor;
	}
]])

redBordersShader = love.graphics.newShader([[
	uniform float healthRatio;
	uniform float aspectRatio;

	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
	{
		const float centerY = 580.0 / 1080.0;
		const float innerRadius = 800.0 / 1080.0;
		const float fadeWidth = 300.0 / 1080.0;

		vec2 distanceFromCenter = texture_coords - vec2(0.5, centerY);
		distanceFromCenter.x *= aspectRatio;

		float centerDistance = length(distanceFromCenter);
		float edge = max((centerDistance - innerRadius) / fadeWidth, 0.0);
		float redness = max(edge * edge - clamp(healthRatio, 0.0, 1.0), 0.0);
		vec4 texcolor = Texel(texture, texture_coords) * color;
		texcolor.rgb = max(texcolor.rgb - vec3(redness / 3.0, redness, redness), vec3(0.0));

		return texcolor;
	}
]])

whiteShader = love.graphics.newShader([[
	uniform vec4 fillColor;

	// passa por cada pixel da imagem e decide a cor final
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
		vec4 pixel = Texel(texture, texture_coords);
		float a = pixel.a;

		if (a <= 0.0) return vec4(0.0);

		return vec4(fillColor.rgb, fillColor.a * a) * color;
	}

]])
