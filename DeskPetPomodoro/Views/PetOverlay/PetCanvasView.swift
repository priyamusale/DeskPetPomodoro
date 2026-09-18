import SwiftUI

class SpriteCache {
    static let shared = SpriteCache()
    private var cache: [String: [CGImage]] = [:]
    
    func getFrames(for imageName: String, columns: Int, rows: Int, frameIndices: [Int]) -> [CGImage] {
        let cacheKey = "\(imageName)_\(columns)x\(rows)_\(frameIndices.map(String.init).joined(separator: "-"))"
        if let cached = cache[cacheKey] {
            return cached
        }
        
        guard let image = NSImage(named: imageName) ?? NSImage(named: imageName + ".png") ?? NSImage(named: imageName + ".jpg") ?? NSImage(named: imageName + ".webp"),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return []
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(data: &pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        
        // Flip coordinate system to match iOS top-down orientation
        context?.translateBy(x: 0, y: CGFloat(height))
        context?.scaleBy(x: 1.0, y: -1.0)
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let bgR = pixelData[0]
        let bgG = pixelData[1]
        let bgB = pixelData[2]
        let bgA = pixelData[3]
        
        // Only remove background if the top-left pixel is opaque
        if bgA > 10 {
            let tolerance: Int = 35
            
            // Flood fill from the edges
            var queue: [(Int, Int)] = []
            var visited = [Bool](repeating: false, count: width * height)
            
            // Seed edges
            for x in 0..<width {
                queue.append((x, 0))
                queue.append((x, height - 1))
            }
            for y in 0..<height {
                queue.append((0, y))
                queue.append((width - 1, y))
            }
            
            var head = 0
            while head < queue.count {
                let (x, y) = queue[head]
                head += 1
                
                let idx = y * width + x
                if visited[idx] { continue }
                visited[idx] = true
                
                let i = idx * 4
                let r = Int(pixelData[i])
                let g = Int(pixelData[i+1])
                let b = Int(pixelData[i+2])
                
                if abs(r - Int(bgR)) < tolerance && abs(g - Int(bgG)) < tolerance && abs(b - Int(bgB)) < tolerance {
                    pixelData[i] = 0
                    pixelData[i+1] = 0
                    pixelData[i+2] = 0
                    pixelData[i+3] = 0 // Transparent
                    
                    if x > 0 { queue.append((x - 1, y)) }
                    if x < width - 1 { queue.append((x + 1, y)) }
                    if y > 0 { queue.append((x, y - 1)) }
                    if y < height - 1 { queue.append((x, y + 1)) }
                }
            }
        }
        
        let frameW = width / columns
        var extracted: [CGImage] = []
        
        let processedCGImage = context?.makeImage() ?? cgImage
        
        // 1. Find global row chunks
        var globalRowMask = [Bool](repeating: false, count: height)
        for y in 0..<height {
            for x in 0..<width {
                let idx = (y * width + x) * 4
                if pixelData[idx+3] > 0 {
                    globalRowMask[y] = true
                    break
                }
            }
        }
        
        var globalChunks: [(minY: Int, maxY: Int)] = []
        var inChunk = false
        var currentMin = 0
        for y in 0..<height {
            if globalRowMask[y] && !inChunk {
                inChunk = true
                currentMin = y
            } else if !globalRowMask[y] && inChunk {
                inChunk = false
                globalChunks.append((minY: currentMin, maxY: y - 1))
            }
        }
        if inChunk { globalChunks.append((minY: currentMin, maxY: height - 1)) }
        
        // Filter out handwritten numbers (noise < 50px)
        globalChunks = globalChunks.filter { $0.maxY - $0.minY > 50 }
        
        // Find the maximum chunk height to unify frame sizes
        let maxChunkH = globalChunks.map { $0.maxY - $0.minY + 1 }.max() ?? (height / rows)
        
        let useChunks = (globalChunks.count == rows)
        
        for i in frameIndices {
            let col = i % columns
            let row = (i / columns) % rows
            
            if useChunks {
                let chunk = globalChunks[row]
                let chunkH = chunk.maxY - chunk.minY + 1
                
                // Crop using mathematical X and global chunk Y
                let cropRect = CGRect(x: CGFloat(col * frameW), y: CGFloat(chunk.minY), width: CGFloat(frameW), height: CGFloat(chunkH))
                
                if let cropped = processedCGImage.cropping(to: cropRect) {
                    // Draw into a uniform canvas so SwiftUI scales all frames identically
                    if let freshContext = CGContext(data: nil, width: frameW, height: maxChunkH, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
                        // Center vertically to maintain stability
                        let destY = (CGFloat(maxChunkH) - CGFloat(chunkH)) / 2.0
                        freshContext.draw(cropped, in: CGRect(x: 0, y: destY, width: CGFloat(frameW), height: CGFloat(chunkH)))
                        if let finalImage = freshContext.makeImage() {
                            extracted.append(finalImage)
                        }
                    }
                }
            } else {
                // Fallback
                let uniformH = height / rows
                let fallbackRect = CGRect(x: CGFloat(col * frameW), y: CGFloat(row * uniformH), width: CGFloat(frameW), height: CGFloat(uniformH))
                if let cropped = processedCGImage.cropping(to: fallbackRect) {
                    extracted.append(cropped)
                }
            }
        }
        
        cache[cacheKey] = extracted
        return extracted
    }
}

struct PetCanvasView: View {
    let variant: PetVariant
    let frameIndex: Int
    let facingRight: Bool
    let isSleeping: Bool
    
    var body: some View {
        if variant.species == .cat {
            if isSleeping {
                SpriteSheetView(
                    variant: variant,
                    imageName: "sleeping_cat",
                    columns: 1, rows: 1, frameIndices: [0],
                    frameIndex: 0, facingRight: facingRight, defaultFacingLeft: false
                )
            } else {
                SpriteSheetView(
                    variant: variant,
                    imageName: "cat_walking",
                    columns: 6, rows: 1, frameIndices: [0, 1, 2, 3, 4, 5],
                    frameIndex: frameIndex, facingRight: facingRight, defaultFacingLeft: false
                )
            }
        } else {
            if isSleeping {
                SpriteSheetView(
                    variant: variant,
                    imageName: "sleeping_dog",
                    columns: 1, rows: 1, frameIndices: [0],
                    frameIndex: 0, facingRight: facingRight, defaultFacingLeft: false
                )
            } else {
                SpriteSheetView(
                    variant: variant,
                    imageName: "dog_walking",
                    columns: 3, rows: 3, frameIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8],
                    frameIndex: frameIndex, facingRight: facingRight, defaultFacingLeft: false
                )
            }
        }
    }
}

struct SpriteSheetView: View {
    let variant: PetVariant
    let imageName: String
    let columns: Int
    let rows: Int
    let frameIndices: [Int]
    let frameIndex: Int
    let facingRight: Bool
    let defaultFacingLeft: Bool
    
    var body: some View {
        let frames = SpriteCache.shared.getFrames(for: imageName, columns: columns, rows: rows, frameIndices: frameIndices)
        
        if frames.isEmpty {
            Text("Error Loading")
                .foregroundColor(.red)
        } else {
            let safeIndex = frameIndex % frames.count
            let shouldFlip = defaultFacingLeft ? facingRight : !facingRight
            
            // On macOS, SwiftUI Image(decorative: cgImage) might assume bottom-up.
            // Using NSImage ensures it respects standard orientation.
            Image(nsImage: NSImage(cgImage: frames[safeIndex], size: .zero))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .scaleEffect(x: shouldFlip ? -1 : 1, y: -1) // Flip vertically because macOS renders the top-down CGImage upside down

                // Color tweaks based on variant ID
                .saturation(variant.id.contains("gray") ? 0.0 : (variant.id.contains("tan") ? 0.4 : 1.0))
                .brightness(variant.id.contains("gray") ? -0.05 : (variant.id.contains("tan") ? 0.15 : 0.0))
        }
    }
}
