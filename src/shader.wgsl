// The shader reads the previous frame's state from the `input` texture, and writes the new state of
// each pixel to the `output` texture. The textures are flipped each step to progress the
// simulation.
// Two textures are needed for the game of life as each pixel of step N depends on the state of its
// neighbors at step N-1.

@group(0) @binding(0) var input: texture_storage_2d<r32float, read>;

@group(0) @binding(1) var output: texture_storage_2d<r32float, write>;

fn hash(value: u32) -> u32 {
    var state = value;
    state = state ^ 2747636419u;
    state = state * 2654435769u;
    state = state ^ state >> 16u;
    state = state * 2654435769u;
    state = state ^ state >> 16u;
    state = state * 2654435769u;
    return state;
}

fn randomFloat(value: u32) -> f32 {
    return f32(hash(value)) / 4294967295.0;
}

const R: f32 = 15.0;      
const T: f32 = 10.0;
const dt: f32 = 1.0/T;
const mu: f32 = 0.14;
const sigma: f32 = 0.014;
const rho: f32 = 0.5;
const omega: f32 = 0.15;

fn bell(x: f32, m: f32, s: f32) -> f32 {
    return exp(-(x - m)*(x-m)/s/s/2.0);
}

@compute @workgroup_size(8, 8, 1)
fn init(@builtin(global_invocation_id) invocation_id: vec3<u32>, @builtin(num_workgroups) num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    if (location.x > 500 && location.x < 1000 && location.y > 200 && location.y < 400) {
        
    let randomNumber = randomFloat(invocation_id.y << 16u | invocation_id.x);
    // let alive = randomNumber > 0.9;
    let color = vec4<f32>(f32(randomNumber));
    // let color = vec4<f32>(f32(alive));

    textureStore(output, location, color);
    } else {
        textureStore(output, location, vec4<f32>(0.0));
    }

}

fn is_alive(location: vec2<i32>, offset_x: i32, offset_y: i32) -> i32 {
    let value: vec4<f32> = textureLoad(input, location + vec2<i32>(offset_x, offset_y));
    return i32(value.x);
}

fn count_alive(location: vec2<i32>) -> i32 {
    return is_alive(location, -1, -1) +
           is_alive(location, -1,  0) +
           is_alive(location, -1,  1) +
           is_alive(location,  0, -1) +
           is_alive(location,  0,  1) +
           is_alive(location,  1, -1) +
           is_alive(location,  1,  0) +
           is_alive(location,  1,  1);
}

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    var sum: f32 = 0.0;
    var total: f32 = 0.0;
    for (var x: i32 = -i32(R); x<=i32(R); x++) {
        for (var y: i32 = -i32(R); y<=i32(R); y++)
        {
            let r: f32 = sqrt(f32(x*x + y*y)) / R;
            let txy: vec2<i32> = (location + vec2<i32>(x, y)); // had iResolution.xy, idk if we need it
            let val: f32 = textureLoad(input, txy).r;
            let weight: f32 = bell(r, rho, omega);
            sum += val * weight;
            total += weight;
        }
        
    }

    let avg: f32 = sum / total;
    let g: f32 = bell(avg, mu, sigma) * 2.0 - 1.0;
    let val: f32 = textureLoad(input, location).r;
    let c: f32 = clamp(val + dt * g, 0.0, 1.0);

    // let n_alive = count_alive(location);

    // var alive: bool;
    // if (n_alive == 3) {
    //     alive = true;
    // } else if (n_alive == 2) {
    //     let currently_alive = is_alive(location, 0, 0);
    //     alive = bool(currently_alive);
    // } else {
    //     alive = false;
    // }
    let color = vec4<f32>(c, c, c, 1.0);
    // let color = vec4<f32>(f32(alive));

    textureStore(output, location, color);
}
