import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

nonisolated struct PhotoAdjustments: Sendable, Equatable {
    var brightness: Float = 0
    var contrast: Float = 1
    var saturation: Float = 1
    var warmth: Float = 6500
    var sharpen: Float = 0
    var vignette: Float = 0
    var highlights: Float = 1
    var shadows: Float = 0
    var exposure: Float = 0
    var vibrance: Float = 0

    static let `default` = PhotoAdjustments()

    var isDefault: Bool {
        self == .default
    }
}

nonisolated struct PhotoFilter: Sendable, Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String

    static let none = PhotoFilter(id: "none", name: "Original", icon: "photo")
    static let vivid = PhotoFilter(id: "vivid", name: "Vivid", icon: "sun.max.fill")
    static let noir = PhotoFilter(id: "noir", name: "Noir", icon: "circle.lefthalf.filled")
    static let chrome = PhotoFilter(id: "chrome", name: "Chrome", icon: "sparkles")
    static let fade = PhotoFilter(id: "fade", name: "Fade", icon: "cloud.fill")
    static let tonal = PhotoFilter(id: "tonal", name: "Tonal", icon: "circle.grid.3x3")
    static let mono = PhotoFilter(id: "mono", name: "Mono", icon: "rectangle.split.1x2.fill")
    static let dramatic = PhotoFilter(id: "dramatic", name: "Dramatic", icon: "theatermasks.fill")
    static let warm = PhotoFilter(id: "warm", name: "Warm", icon: "flame.fill")
    static let cool = PhotoFilter(id: "cool", name: "Cool", icon: "snowflake")
    static let process = PhotoFilter(id: "process", name: "Process", icon: "cpu")
    static let transfer = PhotoFilter(id: "transfer", name: "Transfer", icon: "arrow.right.arrow.left")

    static let allFilters: [PhotoFilter] = [
        .none, .vivid, .noir, .chrome, .fade, .tonal, .mono, .dramatic, .warm, .cool, .process, .transfer
    ]
}

enum PhotoFilterService {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func applyFilter(_ filter: PhotoFilter, to image: UIImage) -> UIImage {
        guard filter != .none else { return image }
        guard let ciImage = CIImage(image: image) else { return image }

        let filtered: CIImage?

        switch filter.id {
        case "vivid":
            filtered = applyVivid(ciImage)
        case "noir":
            filtered = applyNoir(ciImage)
        case "chrome":
            filtered = applyChrome(ciImage)
        case "fade":
            filtered = applyFade(ciImage)
        case "tonal":
            filtered = applyTonal(ciImage)
        case "mono":
            filtered = applyMono(ciImage)
        case "dramatic":
            filtered = applyDramatic(ciImage)
        case "warm":
            filtered = applyWarm(ciImage)
        case "cool":
            filtered = applyCool(ciImage)
        case "process":
            filtered = applyProcess(ciImage)
        case "transfer":
            filtered = applyTransfer(ciImage)
        default:
            filtered = nil
        }

        guard let output = filtered else { return image }
        return renderToUIImage(output, size: image.size) ?? image
    }

    static func applyAdjustments(_ adjustments: PhotoAdjustments, to image: UIImage) -> UIImage {
        guard !adjustments.isDefault else { return image }
        guard var ciImage = CIImage(image: image) else { return image }

        if adjustments.exposure != 0 {
            let exposure = CIFilter.exposureAdjust()
            exposure.inputImage = ciImage
            exposure.ev = adjustments.exposure
            if let out = exposure.outputImage { ciImage = out }
        }

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = ciImage
        colorControls.brightness = adjustments.brightness
        colorControls.contrast = adjustments.contrast
        colorControls.saturation = adjustments.saturation
        if let out = colorControls.outputImage { ciImage = out }

        if adjustments.warmth != 6500 {
            let temp = CIFilter.temperatureAndTint()
            temp.inputImage = ciImage
            temp.neutral = CIVector(x: CGFloat(adjustments.warmth), y: 0)
            if let out = temp.outputImage { ciImage = out }
        }

        if adjustments.vibrance != 0 {
            let vibrance = CIFilter.vibrance()
            vibrance.inputImage = ciImage
            vibrance.amount = adjustments.vibrance
            if let out = vibrance.outputImage { ciImage = out }
        }

        if adjustments.highlights != 1 || adjustments.shadows != 0 {
            let highlight = CIFilter.highlightShadowAdjust()
            highlight.inputImage = ciImage
            highlight.highlightAmount = adjustments.highlights
            highlight.shadowAmount = adjustments.shadows
            if let out = highlight.outputImage { ciImage = out }
        }

        if adjustments.sharpen > 0 {
            let sharpen = CIFilter.sharpenLuminance()
            sharpen.inputImage = ciImage
            sharpen.sharpness = adjustments.sharpen
            if let out = sharpen.outputImage { ciImage = out }
        }

        if adjustments.vignette > 0 {
            let vignette = CIFilter.vignette()
            vignette.inputImage = ciImage
            vignette.intensity = adjustments.vignette
            vignette.radius = 2.0
            if let out = vignette.outputImage { ciImage = out }
        }

        return renderToUIImage(ciImage, size: image.size) ?? image
    }

    static func applyFilterAndAdjustments(filter: PhotoFilter, adjustments: PhotoAdjustments, to image: UIImage) -> UIImage {
        let filtered = applyFilter(filter, to: image)
        return applyAdjustments(adjustments, to: filtered)
    }

    private static func applyVivid(_ image: CIImage) -> CIImage? {
        let controls = CIFilter.colorControls()
        controls.inputImage = image
        controls.saturation = 1.5
        controls.contrast = 1.15
        controls.brightness = 0.02
        guard let step1 = controls.outputImage else { return nil }
        let vibrance = CIFilter.vibrance()
        vibrance.inputImage = step1
        vibrance.amount = 0.5
        return vibrance.outputImage
    }

    private static func applyNoir(_ image: CIImage) -> CIImage? {
        let filter = CIFilter.photoEffectNoir()
        filter.inputImage = image
        return filter.outputImage
    }

    private static func applyChrome(_ image: CIImage) -> CIImage? {
        let filter = CIFilter.photoEffectChrome()
        filter.inputImage = image
        return filter.outputImage
    }

    private static func applyFade(_ image: CIImage) -> CIImage? {
        let filter = CIFilter.photoEffectFade()
        filter.inputImage = image
        return filter.outputImage
    }

    private static func applyTonal(_ image: CIImage) -> CIImage? {
        let filter = CIFilter.photoEffectTonal()
        filter.inputImage = image
        return filter.outputImage
    }

    private static func applyMono(_ image: CIImage) -> CIImage? {
        let filter = CIFilter.photoEffectMono()
        filter.inputImage = image
        return filter.outputImage
    }

    private static func applyDramatic(_ image: CIImage) -> CIImage? {
        let controls = CIFilter.colorControls()
        controls.inputImage = image
        controls.contrast = 1.4
        controls.saturation = 0.7
        controls.brightness = -0.05
        guard let step1 = controls.outputImage else { return nil }
        let vignette = CIFilter.vignette()
        vignette.inputImage = step1
        vignette.intensity = 1.5
        vignette.radius = 2.0
        return vignette.outputImage
    }

    private static func applyWarm(_ image: CIImage) -> CIImage? {
        let temp = CIFilter.temperatureAndTint()
        temp.inputImage = image
        temp.neutral = CIVector(x: 7500, y: 0)
        guard let step1 = temp.outputImage else { return nil }
        let controls = CIFilter.colorControls()
        controls.inputImage = step1
        controls.saturation = 1.15
        controls.brightness = 0.03
        return controls.outputImage
    }

    private static func applyCool(_ image: CIImage) -> CIImage? {
        let temp = CIFilter.temperatureAndTint()
        temp.inputImage = image
        temp.neutral = CIVector(x: 5000, y: 0)
        guard let step1 = temp.outputImage else { return nil }
        let controls = CIFilter.colorControls()
        controls.inputImage = step1
        controls.saturation = 0.9
        controls.contrast = 1.05
        return controls.outputImage
    }

    private static func applyProcess(_ image: CIImage) -> CIImage? {
        let filter = CIFilter.photoEffectProcess()
        filter.inputImage = image
        return filter.outputImage
    }

    private static func applyTransfer(_ image: CIImage) -> CIImage? {
        let filter = CIFilter.photoEffectTransfer()
        filter.inputImage = image
        return filter.outputImage
    }

    private static func renderToUIImage(_ ciImage: CIImage, size: CGSize) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }
}
