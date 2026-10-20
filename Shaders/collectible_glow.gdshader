shader_type canvas_item;

// Makes money pickups readable against busy, colourful backgrounds.
//
// Two-tone silhouette treatment applied to every collectible by
// MarketItem._ready():
//   * an inner dark outline  -> always separates the item from the backdrop
//   * an outer soft glow     -> also makes it pop over dark regions
// The glow gently pulses so the pickup catches the eye even when the player
// isn't looking straight at it.
//
// All sizes are in UV space (0..1 across the sprite), so the effect scales
// with the sprite regardless of the source texture resolution.

// Outer glow colour and reach (in UV units).
uniform vec4 glow_color : source_color = vec4(1.0, 0.94, 0.55, 1.0);
uniform float glow_size : hint_range(0.0, 0.2) = 0.09;
uniform float glow_alpha : hint_range(0.0, 1.0) = 0.55;

// Inner dark outline colour and thickness (in UV units).
uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.10, 1.0);
uniform float outline_size : hint_range(0.0, 0.2) = 0.045;

// Pulse: glow brightness swings between min and full over time.
uniform float pulse_speed : hint_range(0.0, 16.0) = 4.0;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.45;

// Samples the alpha coverage of the silhouette at a ring of the given UV radius.
float silhouette_alpha(sampler2D tex, vec2 uv, float radius) {
	vec2 r = vec2(radius);
	float a = 0.0;
	a = max(a, texture(tex, uv + vec2(r.x, 0.0)).a);
	a = max(a, texture(tex, uv - vec2(r.x, 0.0)).a);
	a = max(a, texture(tex, uv + vec2(0.0, r.y)).a);
	a = max(a, texture(tex, uv - vec2(0.0, r.y)).a);
	a = max(a, texture(tex, uv + r).a);
	a = max(a, texture(tex, uv - r).a);
	a = max(a, texture(tex, uv + vec2(r.x, -r.y)).a);
	a = max(a, texture(tex, uv + vec2(-r.x, r.y)).a);
	return a;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	float pulse = pulse_min + (1.0 - pulse_min) * (0.5 + 0.5 * sin(TIME * pulse_speed));

	float near_a = silhouette_alpha(TEXTURE, UV, outline_size);
	float far_a = silhouette_alpha(TEXTURE, UV, glow_size);

	// Inner dark outline ring (just outside the item).
	float outline_a = clamp(near_a - tex.a, 0.0, 1.0);
	// Outer glow ring (beyond the outline).
	float glow_a = clamp(far_a - near_a, 0.0, 1.0) * glow_alpha * pulse;

	// Slightly brighten the item itself on each pulse so it shimmers.
	vec3 item_rgb = tex.rgb * COLOR.rgb + tex.rgb * 0.2 * pulse;
	float item_a = tex.a * COLOR.a;

	// Composite back-to-front: glow, then outline, then the item on top.
	vec3 rgb = glow_color.rgb;
	float a = glow_a;
	rgb = mix(rgb, outline_color.rgb, outline_a);
	a = max(a, outline_a);
	rgb = mix(rgb, item_rgb, item_a);
	a = max(a, item_a);

	COLOR = vec4(rgb, a);
}