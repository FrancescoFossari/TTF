//
//  Views1.swift
//  TTF app
//
//  Created by Francesco Fossari on 09/04/21.
//
import ParthenoKit
import UIKit
import AVFoundation
import Vision
import SwiftUI

struct ML1: View{
    @Binding var newScene: Bool
    var body: some View {
        ZStack{
            VStack(alignment: .center, spacing: 2){
                Text("Practical advices : ")
                    .font(.system(.largeTitle,design: .rounded))
                    .fontWeight(.bold)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .padding(15)
                
                Text("•Stay in a well-lit environment!")
                    .font(.system(.title, design:.rounded))
                    .frame(minWidth: 10,  maxWidth: 280, minHeight: 10)
                    .padding(10)
                    .cornerRadius(10)
                    .foregroundColor(.black)
                    .offset(x: -38)
                
                Spacer()
                    .frame(height: 20)
                
                Text("•Camera must look the whole body!")
                    .font(.system(.title, design:.rounded))
                    .frame(minWidth: 10,  maxWidth: 280, minHeight: 10)
                    .padding(10)
                    .cornerRadius(10)
                    .foregroundColor(.black)
                
                Spacer()
                    .frame(height: 20)
                
                Text("•Wait 2 seconds before a new repetition!")
                    .font(.system(.title, design:.rounded))
                    .frame(minWidth: 10,  maxWidth: 280, minHeight: 10)
                    .padding(10)
                    .cornerRadius(10)
                    .foregroundColor(.black)
                
                Spacer()
                    .frame(height: 150)
                
                NavigationLink(destination: ActionView(),label:{
                    Text("Start recognition")
                        .font(.system(.largeTitle, design:.rounded))
                        .frame(minWidth: 10,  maxWidth: 280, minHeight: 10)
                        .padding(40)
                        .background(ColorManager.bluemodificato)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    
                    
                 })
 
                .contentShape(Circle())
            }
        }
    }
    init(newScene: Binding<Bool>){
        //mpc.startBrowsing()
        self._newScene = newScene
    }
}


struct ML1_Previews: PreviewProvider {
    static var previews: some View {
        ML1(newScene: .constant(false))
    }
}

struct ActionView: View{
    @State var ciao: String = ""
    @State var labelRes: String = ""
    @State var conta: String = ""
    @State var count: Int = 0
    var body: some View{
        ZStack{
            ActionCameraControllerView(
                labelResult: $labelRes, counter: $count)
                .edgesIgnoringSafeArea(.top)
            
            let label = labelRes + " ("+String( count )+")"
            Text(label)
                .font(.system(size: 40, weight: .heavy, design:
                .default))
                .padding(20)
                .frame(width: 400, height: 200, alignment: .center)
                .position(CGPoint(x:200, y: 500))
                .foregroundColor(Color.white)
            
         //    var ciao = count + ciao
            
        }
    }
}


struct ActionView_Previews: PreviewProvider {
    static var previews: some View {
        ActionView()
    }
}

final class ActionCameraController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var detectionOverlay: CALayer! = nil
    let detectPlayerRequest = VNDetectHumanBodyPoseRequest()
    let bodyPoseDetectionMinConfidence: VNConfidence = 0.6
    let bodyPoseRecognizedPointMinConfidence: VNConfidence = 0.1
    var playerStats = PlayerStats()
    weak var delegate: ActionCameraDelegate?
    
    private let playerBoundingBox = BoundingBoxView()
    private let jointSegmentView = JointSegmentView()
    private var throwRegion = CGRect.null
    private var targetRegion = CGRect.null
    private var playerDetected = false
    
    // Vision parts
    var requests = [VNRequest]()
    
    var previewView: UIView!
    
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var cameraFeedView: CameraFeedView!
    private var videoRenderView: VideoRenderView!
    
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
     func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // to be implemented in the subclass
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform([detectPlayerRequest])
            
            if let result = detectPlayerRequest.results?.first {
                let box = humanBoundingBox(for: result)
                playerDetected = true
                
                let boxView = playerBoundingBox
                DispatchQueue.main.async {
                    let inset: CGFloat = -20.0
                    let viewRect = self.viewRectForVisionRect(box).insetBy(dx: inset, dy: inset)
                    self.updateBoundingBox(boxView, withRect: viewRect)
//                    if !self.playerDetected && !boxView.isHidden {
//                        self.gameManager.stateMachine.enter(GameManager.DetectedPlayerState.self)
//                    }
                }
                
                DispatchQueue.main.async {
                    print(self.playerStats.poseObservations.count)
                    
                    if self.playerStats.poseObservations.count == 60 {
                        
                        let res = self.playerStats.getPrediction()!
                        print("prediction \(res)")
                        
                        self.delegate?.actionRecognized(of: res)
                        
                        self.playerStats.resetObservations()
                    }
                }
            } else {
                // Hide player bounding box
                DispatchQueue.main.async {
                    self.playerDetected = false
                    if !self.playerBoundingBox.isHidden {
                        self.playerBoundingBox.isHidden = true
                        self.jointSegmentView.resetView()
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func viewRectForVisionRect(_ visionRect: CGRect) -> CGRect {
        let flippedRect = visionRect.applying(CGAffineTransform.verticalFlip)
        let viewRect: CGRect
        
        viewRect = previewLayer.layerRectConverted(fromMetadataOutputRect: flippedRect)
        
        return viewRect
    }
    
    func humanBoundingBox(for observation: VNHumanBodyPoseObservation) -> CGRect {
        var box = CGRect.zero
        var normalizedBoundingBox = CGRect.null
        // Process body points only if the confidence is high.
        guard observation.confidence > bodyPoseDetectionMinConfidence, let points = try? observation.recognizedPoints(forGroupKey: .all) else {
            return box
        }
        // Only use point if human pose joint was detected reliably.
        for (_, point) in points where point.confidence > bodyPoseRecognizedPointMinConfidence {
            normalizedBoundingBox = normalizedBoundingBox.union(CGRect(origin: point.location, size: .zero))
        }
        if !normalizedBoundingBox.isNull {
            box = normalizedBoundingBox
        }
        // Fetch body joints from the observation and overlay them on the player.
        //let joints = getBodyJointsFor(observation: observation)
//        DispatchQueue.main.async {
//            self.jointSegmentView.joints = joints
//        }
        
        // Store the body pose observation in playerStats when the game is in TrackThrowsState.
        // We will use these observations for action classification once the throw is complete.
        
        playerStats.storeObservation(observation)
            
        return box
    }
    
    func updateBoundingBox(_ boundingBox: BoundingBoxView, withRect rect: CGRect?) {
        // Update the frame for player bounding box
        boundingBox.frame = rect ?? .zero
        boundingBox.perform(transition: (rect == nil ? .fadeOut : .fadeIn), duration: 0.1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAVCapture()
    }
    
    func setUIElements() {
        playerBoundingBox.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        playerBoundingBox.backgroundOpacity = 0
        playerBoundingBox.isHidden = true
        view.addSubview(playerBoundingBox)
        view.addSubview(jointSegmentView)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupAVCapture() {
        var deviceInput: AVCaptureDeviceInput!
        
        // Select a video device, make an input
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .vga640x480 // Model image size is smaller.
        
        // Add a video input
        guard session.canAddInput(deviceInput) else {
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            try  videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        previewView = UIView(frame: CGRect(x:0, y:0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        previewView.contentMode = UIView.ContentMode.scaleAspectFit
        view.addSubview(previewView)
        
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        //setupVision()
        
        setUIElements()
        // start the capture
        startCaptureSession()
    }
    
    func setupVideoOutputView(_ videoOutputView: UIView) {
        videoOutputView.translatesAutoresizingMaskIntoConstraints = false
        videoOutputView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        view.addSubview(videoOutputView)
        NSLayoutConstraint.activate([
            videoOutputView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoOutputView.rightAnchor.constraint(equalTo: view.rightAnchor),
            videoOutputView.topAnchor.constraint(equalTo: view.topAnchor),
            videoOutputView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func startCaptureSession() {
        session.startRunning()
    }
    
    // Clean up capture setup
    func teardownAVCapture() {
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // print("frame dropped")
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}

protocol ActionCameraDelegate: NSObjectProtocol {
    func actionRecognized(of category: String)
}

struct ActionCameraControllerView: UIViewControllerRepresentable {
    
    public typealias UIViewControllerType = ActionCameraController
    
    @Binding var labelResult: String
    @Binding var counter: Int
    
    public func makeUIViewController(context: UIViewControllerRepresentableContext<ActionCameraControllerView>) -> ActionCameraController
    {
        let a = ActionCameraController()
        a.delegate = context.coordinator
        return a
    }
    
    public func updateUIViewController(_ uiViewController: ActionCameraController, context: UIViewControllerRepresentableContext<ActionCameraControllerView>) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, ActionCameraDelegate {
        
        let parent: ActionCameraControllerView
        
        init(_ parent: ActionCameraControllerView) {
            self.parent = parent
        }
        
        func actionRecognized(of category: String) {
            parent.labelResult = category
            print("Category \(category)")
            if (category=="squat")
            {
                parent.counter = parent.counter + 1
            }
        }
    }
}

class BoundingBoxView: UIView, AnimatedTransitioning {
    
    var borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) {
        didSet {
            setNeedsDisplay()
        }
    }
    var borderCornerSize = CGFloat(10)
    var borderWidth = CGFloat(3)
    var borderCornerRadius = CGFloat(4)
    var backgroundOpacity = CGFloat(1)
    var visionRect = CGRect.null
    var visionPath: CGPath? {
        didSet {
            updatePathLayer()
        }
    }
    
    private let pathLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }

    private func initialSetup() {
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
        pathLayer.strokeColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1).cgColor
        pathLayer.fillColor = UIColor.clear.cgColor
        pathLayer.lineWidth = 2
        layer.addSublayer(pathLayer)
    }
    
    override func draw(_ rect: CGRect) {
        borderColor.setStroke()
        borderColor.withAlphaComponent(backgroundOpacity).setFill()
        let backgroundPath = UIBezierPath(roundedRect: bounds, cornerRadius: borderCornerRadius)
        backgroundPath.fill()
        let borderPath: UIBezierPath
        let borderRect = bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
        if borderCornerSize == 0 {
            borderPath = UIBezierPath(roundedRect: borderRect, cornerRadius: borderCornerRadius)
        } else {
            var cornerSizeH = borderCornerSize
            if cornerSizeH > borderRect.width / 2 - borderCornerRadius {
                cornerSizeH = max(borderRect.width / 2 - borderCornerRadius, 0)
            }
            var cornerSizeV = borderCornerSize
            if cornerSizeV > borderRect.height / 2 - borderCornerRadius {
                cornerSizeV = max(borderRect.height / 2 - borderCornerRadius, 0)
            }
            
            //let cornerSize = CGSize(width: cornerSizeH, height: cornerSizeV)
            
//            borderPath = UIBezierPath(cornersOfRect: borderRect, cornerSize: cornerSize, cornerRadius: borderCornerRadius)
            borderPath =  UIBezierPath(roundedRect: borderRect, cornerRadius: borderCornerRadius)
        }
        borderPath.lineWidth = borderWidth
        borderPath.stroke()
    }
    
    func containedInside(_ otherBox: BoundingBoxView) -> Bool {
        return otherBox.frame.contains(frame)
    }
    
    private func updatePathLayer() {
        guard let visionPath = self.visionPath else {
            pathLayer.path = nil
            return
        }
        let path = UIBezierPath(cgPath: visionPath)
        path.apply(CGAffineTransform.verticalFlip)
        path.apply(CGAffineTransform(scaleX: bounds.width, y: bounds.height))
        pathLayer.path = path.cgPath
    }
}

class JointSegmentView: UIView, AnimatedTransitioning {
    var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:] {
        didSet {
            updatePathLayer()
        }
    }

    private let jointRadius: CGFloat = 3.0
    private let jointLayer = CAShapeLayer()
    private var jointPath = UIBezierPath()

    private let jointSegmentWidth: CGFloat = 2.0
    private let jointSegmentLayer = CAShapeLayer()
    private var jointSegmentPath = UIBezierPath()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    func resetView() {
        jointLayer.path = nil
        jointSegmentLayer.path = nil
    }

    private func setupLayer() {
        jointSegmentLayer.lineCap = .round
        jointSegmentLayer.lineWidth = jointSegmentWidth
        jointSegmentLayer.fillColor = UIColor.clear.cgColor
        jointSegmentLayer.strokeColor = #colorLiteral(red: 0.6078431373, green: 0.9882352941, blue: 0, alpha: 1).cgColor
        layer.addSublayer(jointSegmentLayer)
        let jointColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        jointLayer.strokeColor = jointColor
        jointLayer.fillColor = jointColor
        layer.addSublayer(jointLayer)
    }

    private func updatePathLayer() {
        let flipVertical = CGAffineTransform.verticalFlip
        let scaleToBounds = CGAffineTransform(scaleX: bounds.width, y: bounds.height)
        jointPath.removeAllPoints()
        jointSegmentPath.removeAllPoints()
        // Add all joints and segments
        for index in 0 ..< jointsOfInterest.count {
            if let nextJoint = joints[jointsOfInterest[index]] {
                let nextJointScaled = nextJoint.applying(flipVertical).applying(scaleToBounds)
                let nextJointPath = UIBezierPath(arcCenter: nextJointScaled, radius: jointRadius,
                                                 startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
                jointPath.append(nextJointPath)
                if jointSegmentPath.isEmpty {
                    jointSegmentPath.move(to: nextJointScaled)
                } else {
                    jointSegmentPath.addLine(to: nextJointScaled)
                }
            }
        }
        jointLayer.path = jointPath.cgPath
        jointSegmentLayer.path = jointSegmentPath.cgPath
    }
}

struct PlayerStats {
    var totalScore = 0
    var poseObservations = [VNHumanBodyPoseObservation]()
    let actionClassifier = try! MyActionClassifierSquat(configuration: MLModelConfiguration())
    
    mutating func reset() {
        totalScore = 0
        poseObservations = []
    }

    mutating func resetObservations() {
        poseObservations = []
    }

    mutating func storeObservation(_ observation: VNHumanBodyPoseObservation) {
        if poseObservations.count >= GameConstants.maxPoseObservations {
            poseObservations.removeFirst()
        }
        poseObservations.append(observation)
    }


    mutating func getPrediction() -> String? {
            guard
              let poseMultiArray = prepareInputWithObservations(poseObservations),
              let predictions = try? actionClassifier.prediction(poses: poseMultiArray)
              
        else {
            return nil
        }
        let throwType = predictions.label
        return throwType
    }
}

struct GameConstants {
    static let maxPoseObservations = 60
    static let noObservationFrameLimit = 30
}

let jointsOfInterest: [VNHumanBodyPoseObservation.JointName] = [
    .rightWrist,
    .rightElbow,
    .rightShoulder,
    .rightHip,
    .rightKnee,
    .rightAnkle
]

func armJoints(for observation: VNHumanBodyPoseObservation) -> (CGPoint, CGPoint) {
    var rightElbow = CGPoint(x: 0, y: 0)
    var rightWrist = CGPoint(x: 0, y: 0)

    guard let identifiedPoints = try? observation.recognizedPoints(.all) else {
        return (rightElbow, rightWrist)
    }
    for (key, point) in identifiedPoints where point.confidence > 0.1 {
        switch key {
        case .rightElbow:
            rightElbow = point.location
        case .rightWrist:
            rightWrist = point.location
        default:
            break
        }
    }
    return (rightElbow, rightWrist)
}

extension CGAffineTransform {
    static var verticalFlip = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
}

extension UIBezierPath {
    convenience init(cornersOfRect borderRect: CGRect, cornerSize: CGSize, cornerRadius: CGFloat) {
        self.init()
        let cornerSizeH = cornerSize.width
        let cornerSizeV = cornerSize.height
        // top-left
        move(to: CGPoint(x: borderRect.minX, y: borderRect.minY + cornerSizeV + cornerRadius))
        addLine(to: CGPoint(x: borderRect.minX, y: borderRect.minY + cornerRadius))
        addArc(withCenter: CGPoint(x: borderRect.minX + cornerRadius, y: borderRect.minY + cornerRadius),
               radius: cornerRadius,
               startAngle: CGFloat.pi,
               endAngle: -CGFloat.pi / 2,
               clockwise: true)
        addLine(to: CGPoint(x: borderRect.minX + cornerSizeH + cornerRadius, y: borderRect.minY))
        // top-right
        move(to: CGPoint(x: borderRect.maxX - cornerSizeH - cornerRadius, y: borderRect.minY))
        addLine(to: CGPoint(x: borderRect.maxX - cornerRadius, y: borderRect.minY))
        addArc(withCenter: CGPoint(x: borderRect.maxX - cornerRadius, y: borderRect.minY + cornerRadius),
               radius: cornerRadius,
               startAngle: -CGFloat.pi / 2,
               endAngle: 0,
               clockwise: true)
        addLine(to: CGPoint(x: borderRect.maxX, y: borderRect.minY + cornerSizeV + cornerRadius))
        // bottom-right
        move(to: CGPoint(x: borderRect.maxX, y: borderRect.maxY - cornerSizeV - cornerRadius))
        addLine(to: CGPoint(x: borderRect.maxX, y: borderRect.maxY - cornerRadius))
        addArc(withCenter: CGPoint(x: borderRect.maxX - cornerRadius, y: borderRect.maxY - cornerRadius),
               radius: cornerRadius,
               startAngle: 0,
               endAngle: CGFloat.pi / 2,
               clockwise: true)
        addLine(to: CGPoint(x: borderRect.maxX - cornerSizeH - cornerRadius, y: borderRect.maxY))
        // bottom-left
        move(to: CGPoint(x: borderRect.minX + cornerSizeH + cornerRadius, y: borderRect.maxY))
        addLine(to: CGPoint(x: borderRect.minX + cornerRadius, y: borderRect.maxY))
        addArc(withCenter: CGPoint(x: borderRect.minX + cornerRadius,
                                   y: borderRect.maxY - cornerRadius),
               radius: cornerRadius,
               startAngle: CGFloat.pi / 2,
               endAngle: CGFloat.pi,
               clockwise: true)
        addLine(to: CGPoint(x: borderRect.minX, y: borderRect.maxY - cornerSizeV - cornerRadius))
    }
}

func getBodyJointsFor(observation: VNHumanBodyPoseObservation) -> ([VNHumanBodyPoseObservation.JointName: CGPoint]) {
    var joints = [VNHumanBodyPoseObservation.JointName: CGPoint]()
    guard let identifiedPoints = try? observation.recognizedPoints(.all) else {
        return joints
    }
    for (key, point) in identifiedPoints {
        guard point.confidence > 0.1 else { continue }
        if jointsOfInterest.contains(key) {
            joints[key] = point.location
        }
    }
    return joints
}

// MARK: - Pipeline warmup



// MARK: - Activity Classification Helpers

func prepareInputWithObservations(_ observations: [VNHumanBodyPoseObservation]) -> MLMultiArray? {
    let numAvailableFrames = observations.count
    let observationsNeeded = 60
    var multiArrayBuffer = [MLMultiArray]()

    for frameIndex in 0 ..< min(numAvailableFrames, observationsNeeded) {
        let pose = observations[frameIndex]
        do {
            let oneFrameMultiArray = try pose.keypointsMultiArray()
            multiArrayBuffer.append(oneFrameMultiArray)
        } catch {
            continue
        }
    }
    
    // If poseWindow does not have enough frames (45) yet, we need to pad 0s
    if numAvailableFrames < observationsNeeded {
        for _ in 0 ..< (observationsNeeded - numAvailableFrames) {
            do {
                let oneFrameMultiArray = try MLMultiArray(shape: [1, 3, 18], dataType: .double)
                try resetMultiArray(oneFrameMultiArray)
                multiArrayBuffer.append(oneFrameMultiArray)
            } catch {
                continue
            }
        }
    }
    return MLMultiArray(concatenating: [MLMultiArray](multiArrayBuffer), axis: 0, dataType: .float)
}

func resetMultiArray(_ predictionWindow: MLMultiArray, with value: Double = 0.0) throws {
    let pointer = try UnsafeMutableBufferPointer<Double>(predictionWindow)
    pointer.initialize(repeating: value)
}

// MARK: - Helper extensions




// MARK: - Errors

enum AppError: Error {
    case captureSessionSetup(reason: String)
    case createRequestError(reason: String)
    case videoReadingError(reason: String)
    
    static func display(_ error: Error, inViewController viewController: UIViewController) {
        if let appError = error as? AppError {
            appError.displayInViewController(viewController)
        } else {
            print(error)
        }
    }
    
    func displayInViewController(_ viewController: UIViewController) {
        let title: String?
        let message: String?
        switch self {
        case .captureSessionSetup(let reason):
            title = "AVSession Setup Error"
            message = reason
        case .createRequestError(let reason):
            title = "Error Creating Vision Request"
            message = reason
        case .videoReadingError(let reason):
            title = "Error Reading Recorded Video."
            message = reason
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        viewController.present(alert, animated: true)
    }
}

enum AnimatedTransitionType {
    case fadeIn
    case fadeOut
    case popUp
    case popOut
}

protocol AnimatedTransitioning {
    func perform(transition: AnimatedTransitionType, duration: TimeInterval)
    func perform(transition: AnimatedTransitionType, duration: TimeInterval, completion: (() -> Void)?)
    func perform(transitions: [AnimatedTransitionType], durations: [TimeInterval], delayBetween: TimeInterval, completion: (() -> Void)?)
}

extension AnimatedTransitioning where Self: UIView {
    func perform(transition: AnimatedTransitionType, duration: TimeInterval) {
        perform(transition: transition, duration: duration, completion: nil)
    }
    
    func perform(transition: AnimatedTransitionType, duration: TimeInterval, completion: (() -> Void)?) {
        switch transition {
        case .fadeIn:
            UIView.transition(with: self, duration: duration, options: .transitionCrossDissolve) {
                self.isHidden = false
            } completion: { _ in
                completion?()
            }
        case .fadeOut:
            UIView.transition(with: self, duration: duration, options: .transitionCrossDissolve) {
                self.isHidden = true
            } completion: { _ in
                completion?()
            }
        case .popUp:
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 5,
                           options: [.curveEaseIn], animations: {
                self.transform = CGAffineTransform.identity
                self.alpha = 1
            }) { _ in
                completion?()
            }
        case .popOut:
            alpha = 1
            transform = CGAffineTransform.identity
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
                self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                self.alpha = 0
            }) { _ in
                completion?()
            }
        }
    }
    
    func perform(transitions: [AnimatedTransitionType], durations: [TimeInterval],
                 delayBetween: TimeInterval, completion: (() -> Void)?) {

        guard let transition = transitions.first else {
            completion?()
            return
        }
        
        let duration = durations.first ?? 0.25
        let view = self
        view.perform(transition: transition, duration: duration) {
            let remainingTransitions = Array(transitions.dropFirst())
            let remainingDurations = Array(durations.dropFirst())
            if !remainingTransitions.isEmpty {
                Timer.scheduledTimer(withTimeInterval: delayBetween, repeats: false) { _ in
                    view.perform(transitions: remainingTransitions, durations: remainingDurations, delayBetween: delayBetween, completion: completion)
                }
            } else {
                completion?()
            }
        }
    }
}

extension ActionCameraController {
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        CATransaction.commit()
    }
}

protocol NormalizedGeometryConverting {
    func viewRectConverted(fromNormalizedContentsRect normalizedRect: CGRect) -> CGRect
    func viewPointConverted(fromNormalizedContentsPoint normalizedPoint: CGPoint) -> CGPoint
}

// MARK: - View to display live camera feed
class CameraFeedView: UIView, NormalizedGeometryConverting {
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    init(frame: CGRect, session: AVCaptureSession, videoOrientation: AVCaptureVideoOrientation) {
        super.init(frame: frame)
        previewLayer = layer as? AVCaptureVideoPreviewLayer
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspect
        previewLayer.connection?.videoOrientation = videoOrientation
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewRectConverted(fromNormalizedContentsRect normalizedRect: CGRect) -> CGRect {
        return previewLayer.layerRectConverted(fromMetadataOutputRect: normalizedRect)
    }

    func viewPointConverted(fromNormalizedContentsPoint normalizedPoint: CGPoint) -> CGPoint {
        return previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
    }
}

// MARK: - View for rendering video file contents
class VideoRenderView: UIView, NormalizedGeometryConverting {
    private var renderLayer: AVPlayerLayer!
    
    var player: AVPlayer? {
        get {
            return renderLayer.player
        }
        set {
            renderLayer.player = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        renderLayer = layer as? AVPlayerLayer
        renderLayer.videoGravity = .resizeAspect
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewRectConverted(fromNormalizedContentsRect normalizedRect: CGRect) -> CGRect {
        let videoRect = renderLayer.videoRect
        let origin = CGPoint(x: videoRect.origin.x + normalizedRect.origin.x * videoRect.width,
                             y: videoRect.origin.y + normalizedRect.origin.y * videoRect.height)
        let size = CGSize(width: normalizedRect.width * videoRect.width,
                          height: normalizedRect.height * videoRect.height)
        let convertedRect = CGRect(origin: origin, size: size)
        return convertedRect.integral
    }

    func viewPointConverted(fromNormalizedContentsPoint normalizedPoint: CGPoint) -> CGPoint {
        let videoRect = renderLayer.videoRect
        let convertedPoint = CGPoint(x: videoRect.origin.x + normalizedPoint.x * videoRect.width,
                                     y: videoRect.origin.y + normalizedPoint.y * videoRect.height)
        return convertedPoint
    }
}

struct PlayAlone: View{
    var body: some View{
        ML1(newScene: .constant(false))
    }
}


