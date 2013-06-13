shaders = {}

shaders.effects = {}

shaders.background = {}
shaders.effects.background = love.graphics.newPixelEffect[[
    uniform float tau = 6.28318530712;

    extern float mapx;
    extern float mapy;
    extern float block_size;
    extern float field_size;

    extern float time;

    // vec3 hue2rgb(float hue) {
    //     hue = mod(hue, 360);
    //
    //     vec3 rgb = vec3(0, 0, 0);
    //
    //     float hdash = hue / 60.0;
    //     float n = 1 * (1.0 - abs((mod(hdash, 2.0)) - 1.0));
    //
    //     if(hdash < 1.0) {
    //         rgb.r = 1;
    //         rgb.g = n;
    //     } else if(hdash < 2.0) {
    //         rgb.r = n;
    //         rgb.g = 1;
    //     } else if(hdash < 3.0) {
    //         rgb.g = 1;
    //         rgb.b = n;
    //     } else if(hdash < 4.0) {
    //         rgb.g = n;
    //         rgb.b = 1;
    //     } else if(hdash < 5.0) {
    //         rgb.r = n;
    //         rgb.b = 1;
    //     } else if(hdash <= 6.0) {
    //         rgb.r = 1;
    //         rgb.b = n;
    //     }
    //
    //     return rgb;
    // }

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
        vec4 pixel = vec4(0);
        pixel_coords.y = (768-pixel_coords.y);

        pixel.r += 0.2;
        pixel.g += 0.2;
        pixel.b += 0.2;

        float n;

        float dx = (pixel_coords.x + mapx) / block_size;
        float dy = (pixel_coords.y - mapy) / block_size;
        float dist = sqrt(dx*dx + dy*dy);

        if((((pixel_coords.x + mapx) - block_size/2) / block_size) > field_size || (((pixel_coords.y + mapy) - block_size/2) / block_size) > field_size ||
        (((pixel_coords.x + mapx) - block_size/2) / block_size) + 1 < -field_size || (((pixel_coords.y + mapy) - block_size/2) / block_size) + 1 < -field_size) {
            float mx = abs(pixel_coords.x + mapx);
            float my = abs(pixel_coords.y + mapy);
            n = (max(mx, my) - (field_size/block_size - 4) * block_size) / 300;
            n = 1 - n;
            n = clamp(n, 0.4, 1);
            pixel.r = n;
            pixel.g = n;
            pixel.b = n;
        } else {
            n = clamp(dist / 250, 0, 0.4);
            n += mod(pixel_coords.x + mapx - block_size/2, block_size) / block_size * 0.02;
            n += mod(pixel_coords.y + mapy - block_size/2, block_size) / block_size * 0.02;
            n = 0.5 - n;
        }
            
        pixel.r = n;
        pixel.g = n;
        pixel.b = n;

        pixel.a = 1;

        return pixel;
    }
]]

shaders.menu_background = {}
shaders.menu_background.yscroll = 1
shaders.menu_background.alpha = 1
shaders.effects.menu_background = love.graphics.newPixelEffect[[
    extern float time;
    extern float yscroll;
    extern float alpha;

    vec4 hsv_to_rgb(float h, float s, float v, float a) {
        float c = v * s;
        h = mod((h * 6.0), 6.0);
        float x = c * (1.0 - abs(mod(h, 2.0) - 1.0));
        vec4 color;
     
        if (0.0 <= h && h < 1.0) {
            color = vec4(c, x, 0.0, a);
        } else if (1.0 <= h && h < 2.0) {
            color = vec4(x, c, 0.0, a);
        } else if (2.0 <= h && h < 3.0) {
            color = vec4(0.0, c, x, a);
        } else if (3.0 <= h && h < 4.0) {
            color = vec4(0.0, x, c, a);
        } else if (4.0 <= h && h < 5.0) {
            color = vec4(x, 0.0, c, a);
        } else if (5.0 <= h && h < 6.0) {
            color = vec4(c, 0.0, x, a);
        } else {
            color = vec4(0.0, 0.0, 0.0, a);
        }
     
        color.rgb += v - c;
     
        return color;
    }

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
        vec4 pixel = hsv_to_rgb(mod(time / 50, 1), 0.4, 0.6, alpha);

        mat2 rotation = mat2(
            vec2( cos(1.3),  sin(1.3)),
            vec2(-sin(1.3),  cos(1.3))
        );

        vec2 rotated = (rotation * pixel_coords);
        rotated.x += time * -24;
        rotated.y += yscroll;

        if(mod(rotated.x, 100) > 5 && mod(rotated.y, 100) > 5) {
            pixel.rgb *= clamp(floor(rotated.y / 100) / 70 + 1.1, 1.1, 1.5);
        }

        return pixel;
    }
]]


function shaders.update()
    shaders.effects.background:send("mapx", game.mapx)
    shaders.effects.background:send("mapy", game.mapy)
    shaders.effects.background:send("block_size", game.block_size)
    shaders.effects.background:send("field_size", game.field_size)


    shaders.effects.menu_background:send("time", game.time)

    if net.connected then
        shaders.menu_background.yscroll = shaders.menu_background.yscroll * 1.1
        if shaders.menu_background.yscroll > 50 then
            shaders.menu_background.alpha = shaders.menu_background.alpha - 0.02
        end
    else
        shaders.menu_background.yscroll = 10
        shaders.menu_background.alpha = 1
    end

    shaders.effects.menu_background:send("yscroll", shaders.menu_background.yscroll)
    shaders.effects.menu_background:send("alpha", shaders.menu_background.alpha)
end
