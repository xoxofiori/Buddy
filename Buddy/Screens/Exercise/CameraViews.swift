import AVFoundation
import SwiftUI

/// Live front-camera picture (mirrored), filling the panel. The camera delivers a 3:4 picture,
/// so a wide panel only trims a little off the top and bottom.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        override func layoutSubviews() {
            super.layoutSubviews()
            if let connection = previewLayer.connection, connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
    }
}

/// Draws a skeleton: the kid's over the camera picture, or the guide figure in the demo.
/// The joints Buddy measures for this exercise are highlighted.
struct SkeletonOverlay: View {
    let frame: PoseFrame?
    let kind: ExerciseKind
    /// Fill the panel like the camera preview does (true), or fit the whole picture (false).
    var fill = true
    /// Only show this part of the picture (0–1 coordinates), e.g. to zoom in on the guide figure.
    var crop: CGRect? = nil
    var lineWidth: CGFloat = 5

    private static let bones: [(Joint, Joint)] = [
        (.nose, .neck),
        (.leftShoulder, .rightShoulder), (.leftHip, .rightHip),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
    ]

    private var keyJoints: Set<Joint> {
        kind == .armRaises
            ? [.leftShoulder, .rightShoulder, .leftWrist, .rightWrist, .leftElbow, .rightElbow]
            : [.leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle]
    }

    var body: some View {
        Canvas { ctx, size in
            guard let frame else { return }
            // Map the (cropped) picture into the panel the same way the camera preview does.
            let area = crop ?? CGRect(x: 0, y: 0, width: 1, height: 1)
            let image = CGSize(width: frame.imageSize.width * area.width, height: frame.imageSize.height * area.height)
            let scale = fill ? max(size.width / image.width, size.height / image.height)
                             : min(size.width / image.width, size.height / image.height)
            let dx = (size.width - image.width * scale) / 2
            let dy = (size.height - image.height * scale) / 2
            func place(_ j: Joint) -> CGPoint? {
                frame.point(j).map {
                    CGPoint(x: ($0.x - area.minX) * frame.imageSize.width * scale + dx,
                            y: ($0.y - area.minY) * frame.imageSize.height * scale + dy)
                }
            }
            let outline = lineWidth + 4

            for (a, b) in Self.bones {
                guard let pa = place(a), let pb = place(b) else { continue }
                var line = Path()
                line.move(to: pa)
                line.addLine(to: pb)
                let key = keyJoints.contains(a) && keyJoints.contains(b)
                ctx.stroke(line, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: outline, lineCap: .round))
                ctx.stroke(line, with: .color(key ? .coral : .sprout), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
            for joint in Joint.allCases {
                guard let p = place(joint) else { continue }
                let r: CGFloat = (keyJoints.contains(joint) ? 1.4 : 1) * lineWidth
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - r - 2, y: p.y - r - 2, width: (r + 2) * 2, height: (r + 2) * 2)), with: .color(.white))
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                         with: .color(keyJoints.contains(joint) ? .sunny : .sky))
            }
        }
        .allowsHitTesting(false)
    }
}
