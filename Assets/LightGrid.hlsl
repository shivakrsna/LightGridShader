void LightGrid_float(UnityTexture2D source, float2 uv, out float3 outColor)
{
    // Grid parameters
    float gridU = 160;       // horizontal dot slots for R/G rows
    float rowsV = 90;        // total rows (RG and B rows)

    // Dot appearance
    float dotRadius = 0.05;  // base radius of each LED dot
    float edgeSoft  = 0.18;  // edge feathering
    float coreBoost = 0.45;  // extra brightness near the center

    // Base grid in UV space (measured in RG dot slots horizontally)
    float2 gridSize = float2(gridU, rowsV);
    float2 g = uv * gridSize;

    // Choose one hot channel based on the pattern
    bool2 parity = frac(floor(g) / 2) > 0.49999;
    float wR =  parity.y &&  parity.x;  // odd rows, odd columns
    float wG =  parity.y && !parity.x;  // odd rows, even columns
    float wB = !parity.y;               // even rows

    // Sample the source per grid type
    float2 uvRG = floor(uv * gridSize / 2) / (gridSize / 2);
    float3 src = SAMPLE_TEXTURE2D(source.tex, source.samplerstate, uvRG).rgb;

    // Local coordinates in the current dot cell, centered at 0
    float dRG = length(frac(g) - 0.5);
    float shapeRG = 1 - smoothstep(dotRadius, dotRadius + edgeSoft, dRG);
    float coreRG = saturate(1 - dRG / dotRadius);
    float ampRG = shapeRG + coreRG * coreRG * coreRG * coreBoost;

    float2 cellB = frac(g * float2(0.5, 1)) * float2(2, 1) - float2(1, 0.5);
    float dB = length(cellB);
    float shapeB = 1 - smoothstep(dotRadius, dotRadius + edgeSoft, dB);
    float coreB = saturate(1 - dB / dotRadius);
    float ampB = shapeB + coreB * coreB * coreB * coreBoost;

    // Color composition
    outColor = src * float3(wR, wG, wB) * float3(ampRG, ampRG, ampB);
}
