import Foundation

/// Pure auto-scroll math, isolated from any view so it can be tested and reused. The overlay
/// asks for the offset at a given moment; manual scrubbing simply overrides the result.
public enum ScrollMetrics {
    public static func offset(
        elapsed: TimeInterval,
        speed: Double,
        startDelay: TimeInterval,
        maxOffset: Double
    ) -> Double {
        let ceiling = max(0, maxOffset)
        guard elapsed > startDelay else { return 0 }
        let travelled = speed * (elapsed - startDelay)
        return min(max(0, travelled), ceiling)
    }
}
