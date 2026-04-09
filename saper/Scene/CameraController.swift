import SpriteKit

/// Pan gesture recognizer with a minimum translation threshold.
/// Only transitions to .began after the finger moves at least the threshold distance.
/// If the touch ends before the threshold is reached, the gesture fails — allowing
/// tap gestures that require(toFail:) this pan to fire immediately.
class ThresholdPanGestureRecognizer: UIPanGestureRecognizer {
    let threshold: CGFloat
    private var initialTouchPoint: CGPoint = .zero
    private(set) var hasExceededThreshold = false

    init(target: Any?, action: Selector?, threshold: CGFloat = 8) {
        self.threshold = threshold
        super.init(target: target, action: action)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first {
            initialTouchPoint = touch.location(in: view)
        }
        hasExceededThreshold = false
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first else {
            super.touchesMoved(touches, with: event)
            return
        }

        if !hasExceededThreshold {
            let currentPoint = touch.location(in: view)
            let dx = currentPoint.x - initialTouchPoint.x
            let dy = currentPoint.y - initialTouchPoint.y
            let distance = sqrt(dx * dx + dy * dy)
            if distance >= threshold {
                hasExceededThreshold = true
                // Reset translation so the camera starts from 0 at this point
                super.touchesMoved(touches, with: event)
                setTranslation(.zero, in: view)
            }
            // Don't call super until threshold exceeded — prevents state from advancing
            return
        }

        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if !hasExceededThreshold {
            // Finger lifted before moving enough — fail the gesture
            state = .failed
            return
        }
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        if !hasExceededThreshold {
            state = .failed
            return
        }
        super.touchesCancelled(touches, with: event)
    }

    override func reset() {
        super.reset()
        hasExceededThreshold = false
        initialTouchPoint = .zero
    }
}

/// Handles camera pan and zoom gestures.
class CameraController {
    weak var cameraNode: SKCameraNode?
    weak var scene: SKScene?

    private var lastPanTranslation: CGPoint = .zero
    private var initialPinchScale: CGFloat = 1.0
    private(set) var panGesture: ThresholdPanGestureRecognizer?

    var onCameraMoved: (() -> Void)?

    func setupGestures(in view: SKView) {
        // Single-finger pan with threshold to separate from tap
        let pan = ThresholdPanGestureRecognizer(target: self, action: #selector(handlePan(_:)), threshold: 8)
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 2
        pan.delegate = GestureDelegate.shared
        view.addGestureRecognizer(pan)
        self.panGesture = pan

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = GestureDelegate.shared
        view.addGestureRecognizer(pinch)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let camera = cameraNode else { return }

        switch gesture.state {
        case .began:
            lastPanTranslation = .zero
        case .changed:
            let translation = gesture.translation(in: gesture.view)
            let delta = CGPoint(
                x: translation.x - lastPanTranslation.x,
                y: translation.y - lastPanTranslation.y
            )
            lastPanTranslation = translation

            camera.position = CGPoint(
                x: camera.position.x - delta.x * camera.xScale,
                y: camera.position.y + delta.y * camera.yScale
            )
            onCameraMoved?()
        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let camera = cameraNode else { return }

        switch gesture.state {
        case .began:
            initialPinchScale = camera.xScale
        case .changed:
            let newScale = initialPinchScale / gesture.scale
            let clampedScale = max(Constants.minCameraScale, min(Constants.maxCameraScale, newScale))
            camera.setScale(clampedScale)
            onCameraMoved?()
        default:
            break
        }
    }

    /// Get the visible world rect based on camera position and scale.
    func visibleWorldRect(viewSize: CGSize) -> CGRect {
        guard let camera = cameraNode else { return .zero }
        let scaledWidth = viewSize.width * camera.xScale
        let scaledHeight = viewSize.height * camera.yScale
        return CGRect(
            x: camera.position.x - scaledWidth / 2,
            y: camera.position.y - scaledHeight / 2,
            width: scaledWidth,
            height: scaledHeight
        )
    }

    /// Get the sector coordinate at the center of the camera.
    func centerSectorCoordinate() -> SectorCoordinate {
        guard let camera = cameraNode else { return SectorCoordinate(x: 0, y: 0) }
        let sx = Int(floor(camera.position.x / Constants.sectorPixelSize))
        let sy = Int(floor(camera.position.y / Constants.sectorPixelSize))
        return SectorCoordinate(x: sx, y: sy)
    }
}

/// Shared delegate to allow simultaneous gesture recognition.
private class GestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = GestureDelegate()

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Allow pan + pinch simultaneously
        if gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer { return true }
        if gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer { return true }
        // Allow pan to coexist with long press (so flagging works during panning)
        if gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UILongPressGestureRecognizer { return true }
        return false
    }
}
