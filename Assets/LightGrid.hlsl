// Converts an input texture into an RGB LED grid look.
// This version hard-codes tunable parameters as locals for clarity.
// Later they can be exposed as Shader Graph inputs.
void LightGrid_float(UnityTexture2D source, float2 uv, out float3 outColor)
{
    // Panel parameters (to be exposed later)
    // Number of RGB triads across U and rows across V
    float triadsU = 80.0;     // horizontal triads (RGB groups)
    float rowsV   = 140.0;      // vertical rows

    // Dot appearance inside a subpixel cell (0..0.5 is from center to edge)
    float dotRadius   = 0.32;  // base radius of each LED dot
    float edgeSoft    = 0.08;  // edge feathering
    float coreBoost   = 0.75;  // extra brightness near the center
    float corePower   = 3.0;   // center falloff power
    float background  = 0.02;  // dark leakage for off areas

    // Subpixel grid in UV space (three columns per triad)
    float2 subGridSize = float2(triadsU * 3.0, rowsV);
    float2 g = uv * subGridSize;

    // Local coordinates in the current subpixel cell, centered at 0
    float2 cell = frac(g) - 0.5;

    // Identify the triad this subpixel belongs to (integer coordinates)
    float triadX = floor(g.x / 3.0);
    float triadY = floor(g.y);

    // Sample the source once per triad so R/G/B share the same texel
    float2 triadUV = (float2(triadX, triadY) + 0.5) / float2(triadsU, rowsV);
    float3 src = SAMPLE_TEXTURE2D(source.tex, source.samplerstate, triadUV).rgb;

    // Row-based subpixel pattern
    // Odd rows: G/R alternating by column, Even rows: B only
    float rowParity = fmod(triadY, 2.0);                      // 0=even, 1=odd
    float colParity = fmod(floor(g.x), 2.0);

    // Choose one hot channel based on the pattern
    float wR = (rowParity > 0.5) ? step(0.5, colParity) : 0.0;  // odd rows, odd columns
    float wG = (rowParity > 0.5) ? (1.0 - step(0.5, colParity)) : 0.0; // odd rows, even columns
    float wB = (rowParity < 0.5) ? 1.0 : 0.0;                    // even rows

    float3 triadColor = float3(src.r * wR, src.g * wG, src.b * wB);

    // Compute two footprints: RG rows use the default subpixel grid.
    // B rows have half the horizontal dot density and are shifted by 0.5 cell.
    float2 cellRG = cell;
    float2 gB = float2(g.x * 0.5 + 0.25, g.y); // half frequency + half-cell shift
    // Additional horizontal phase for blue row: shift by 0.5 dot
    float bPhase = 0.5; // in B-dot units
    gB.x += bPhase;
    float2 cellB  = frac(gB) - 0.5;
    // Keep absolute dot width equal to RG by compensating the wider cell
    cellB.x *= 2.0;
    // Shift B-dot horizontally by half a dot (0.5×diameter = radius)
    float shiftB = 2.0 * dotRadius; // full-dot shift (additional +0.5 dot)
    cellB.x += shiftB;

    float dRG = length(cellRG);
    float aaRG = fwidth(dRG);
    float shapeRG = 1.0 - smoothstep(dotRadius, dotRadius + max(edgeSoft, aaRG), dRG);
    float coreRG = pow(saturate(1.0 - dRG / max(dotRadius, 1e-4)), corePower) * coreBoost;
    float ampRG = shapeRG + coreRG;

    float dB = length(cellB);
    float aaB = fwidth(dB);
    float shapeB = 1.0 - smoothstep(dotRadius, dotRadius + max(edgeSoft, aaB), dB);
    float coreB = pow(saturate(1.0 - dB / max(dotRadius, 1e-4)), corePower) * coreBoost;
    float ampB = (shapeB + coreB); // blue row: half COUNT, not half brightness

    // Compose per-row pattern
    float3 colorRG = float3(src.r * wR, src.g * wG, 0.0) * ampRG;
    float3 colorB  = float3(0.0, 0.0, src.b * wB) * ampB;
    float3 color = colorRG + colorB + background * triadColor;

    outColor = color;
}
