shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.3, 1.0, 0.45, 0.75);
uniform float outline_size = 2.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a > 0.01) {
		COLOR = vec4(0.0);
	} else {
		vec2 pixel = TEXTURE_PIXEL_SIZE * outline_size;
		float alpha = 0.0;
		alpha = max(alpha, texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a);
		alpha = max(alpha, texture(TEXTURE, UV + vec2(-pixel.x, 0.0)).a);
		alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0, pixel.y)).a);
		alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0, -pixel.y)).a);
		alpha = max(alpha, texture(TEXTURE, UV + vec2(pixel.x, pixel.y)).a);
		alpha = max(alpha, texture(TEXTURE, UV + vec2(-pixel.x, pixel.y)).a);
		alpha = max(alpha, texture(TEXTURE, UV + vec2(pixel.x, -pixel.y)).a);
		alpha = max(alpha, texture(TEXTURE, UV + vec2(-pixel.x, -pixel.y)).a);

		COLOR = vec4(outline_color.rgb, outline_color.a * alpha);
	}
}
