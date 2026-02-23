import SwiftUI
import AppKit
import AVFoundation
import CoreImage

// MARK: - Camera QR Scanner (SwiftUI wrapper)
struct CameraQRScannerView: NSViewRepresentable {
    let onQRCodeDetected: (String) -> Void
    func makeNSView(context: Context) -> CameraPreviewNSView {
        let v = CameraPreviewNSView(); v.onQRCodeDetected = onQRCodeDetected; return v
    }
    func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {}
}

// MARK: - Camera Preview NSView
class CameraPreviewNSView: NSView {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoOutput: AVCaptureVideoDataOutput?
    var onQRCodeDetected: ((String) -> Void)?
    
    override init(frame: NSRect) { super.init(frame: frame); wantsLayer = true }
    required init?(coder: NSCoder) { super.init(coder: coder); wantsLayer = true }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil { startCamera() } else { stopCamera() }
    }
    
    private func startCamera() {
        let session = AVCaptureSession(); session.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) else { return }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCMPixelFormat_32BGRA]
            output.alwaysDiscardsLateVideoFrames = true
            if session.canAddOutput(output) { session.addOutput(output) }
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill; layer.backgroundColor = NSColor.black.cgColor
            layer.cornerRadius = 8; layer.masksToBounds = true
            DispatchQueue.main.async { self.previewLayer = layer; layer.frame = self.bounds; self.layer?.addSublayer(layer) }
            session.commitConfiguration(); self.captureSession = session; self.videoOutput = output
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
            session.startRunning()
        } catch { print("Camera error: \(error)") }
    }
    
    func stopCamera() {
        captureSession?.stopRunning(); captureSession = nil; videoOutput = nil
        previewLayer?.removeFromSuperlayer(); previewLayer = nil
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize); previewLayer?.frame = bounds
    }
}

extension CameraPreviewNSView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature], let qr = features.first, let payload = qr.messageString else { return }
        DispatchQueue.main.async { self.stopCamera(); self.onQRCodeDetected?(payload) }
    }
}

// MARK: - Image Picker
struct ImagePicker: NSViewControllerRepresentable {
    @Binding var selectedImage: NSImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeNSViewController(context: Context) -> NSViewController {
        let picker = NSOpenPanel()
        picker.allowedContentTypes = [.image]; picker.allowsMultipleSelection = false
        picker.canChooseDirectories = false; picker.canChooseFiles = true
        let controller = NSViewController()
        DispatchQueue.main.async {
            picker.begin { response in
                if response == .OK, let url = picker.url { selectedImage = NSImage(contentsOf: url) }
                presentationMode.wrappedValue.dismiss()
            }
        }
        return controller
    }
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

// MARK: - Import QR Code Image View
struct ImportQRCodeImageView: View {
    let onQRCodeScanned: (String) -> Void
    let onJoinStatusUpdated: (String) -> Void
    @State private var showingImagePicker = false
    @State private var selectedImage: NSImage?
    @State private var scannedCode = ""
    @State private var scannedSSID: String?
    @State private var scannedPassword: String?
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 36))
                    .foregroundColor(.green)
                Text("Import a QR Code Image")
                    .font(.headline)
                Text("Select an image file containing a WiFi QR code")
                    .font(.body).foregroundColor(.secondary)
                Button("Select Image") { showingImagePicker = true }
                    .buttonStyle(.borderedProminent).controlSize(.large)
            }
            .padding().background(Color.green.opacity(0.1)).cornerRadius(12)
            
            if let image = selectedImage {
                VStack(spacing: 12) {
                    Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 180).cornerRadius(12).shadow(radius: 5)
                    Button("Process QR Code") { processQRCode() }
                        .buttonStyle(.bordered).controlSize(.large)
                }
            }
            
            if scannedSSID != nil || scannedPassword != nil {
                VStack(spacing: 12) {
                    if let ssid = scannedSSID, let pw = scannedPassword {
                        HStack { Text("Network:").foregroundColor(.secondary); Spacer(); Text(ssid).font(.system(.body, design: .monospaced)) }.padding(.horizontal)
                        HStack { Text("Password:").foregroundColor(.secondary); Spacer(); Text(pw).font(.system(.body, design: .monospaced)) }.padding(.horizontal)
                    }
                    Button("Use This WiFi") {
                        if let s = scannedSSID, let p = scannedPassword {
                            onQRCodeScanned("WIFI:T:WPA;S:\(s);P:\(p);H:false;;")
                        } else { onQRCodeScanned(scannedCode) }
                    }.buttonStyle(.borderedProminent)
                }
                .padding().background(Color.green.opacity(0.1)).cornerRadius(12).frame(maxWidth: 500)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingImagePicker) { ImagePicker(selectedImage: $selectedImage) }
    }
    
    private func processQRCode() {
        guard let image = selectedImage, let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let ciImage = CIImage(cgImage: cgImage)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature], let feature = features.first else {
            scannedCode = "No QR code found"; return
        }
        scannedCode = feature.messageString ?? ""
        let (ssid, password) = QRCodeGenerator.parseWiFiQRCode(scannedCode)
        scannedSSID = ssid; scannedPassword = password
    }
}

// MARK: - Live Scan QR Code View
struct LiveScanQRCodeView: View {
    let onQRCodeScanned: (String) -> Void
    let onJoinStatusUpdated: (String) -> Void
    @State private var scannedCode = ""
    @State private var showingCamera = false
    @State private var scannedSSID: String?
    @State private var scannedPassword: String?
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
                Text("Live Camera Scanning")
                    .font(.headline)
                Text("Use your Mac's camera to scan a QR code in real-time")
                    .font(.body).foregroundColor(.secondary)
                Button("Scan QR Code") { showingCamera = true }
                    .buttonStyle(.borderedProminent).controlSize(.large)
            }
            .padding().background(Color.blue.opacity(0.1)).cornerRadius(12)
            
            if scannedSSID != nil || scannedPassword != nil {
                VStack(spacing: 12) {
                    if let ssid = scannedSSID, let pw = scannedPassword {
                        HStack { Text("Network:").foregroundColor(.secondary); Spacer(); Text(ssid).font(.system(.body, design: .monospaced)) }.padding(.horizontal)
                        HStack { Text("Password:").foregroundColor(.secondary); Spacer(); Text(pw).font(.system(.body, design: .monospaced)) }.padding(.horizontal)
                    }
                    Button("Use This WiFi") {
                        if let s = scannedSSID, let p = scannedPassword {
                            onQRCodeScanned("WIFI:T:WPA;S:\(s);P:\(p);H:false;;")
                        } else { onQRCodeScanned(scannedCode) }
                    }.buttonStyle(.borderedProminent)
                }
                .padding().background(Color.green.opacity(0.1)).cornerRadius(12).frame(maxWidth: 500)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingCamera) {
            CameraQRScannerView(onQRCodeDetected: { qrString in
                scannedCode = qrString
                let (ssid, pw) = QRCodeGenerator.parseWiFiQRCode(qrString)
                scannedSSID = ssid; scannedPassword = pw; showingCamera = false
                if let s = ssid, let p = pw { onQRCodeScanned("WIFI:T:WPA;S:\(s);P:\(p);H:false;;") }
            })
        }
    }
}

// MARK: - UI Components
struct NavigationButton: View {
    let title: String; let icon: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title3)
                    .foregroundColor(isSelected ? .accentColor : .secondary).frame(width: 20)
                Text(title).font(.body).foregroundColor(isSelected ? .primary : .secondary)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 6).fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear))
        }.buttonStyle(PlainButtonStyle())
    }
}

struct ResultCard: View {
    let title: String; let content: String; let description: String; let color: Color; let actionTitle: String; let action: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Text(title).font(.headline); Spacer(); Button(actionTitle, action: action).buttonStyle(.bordered).controlSize(.small) }
            VStack(alignment: .leading, spacing: 8) {
                Text(content).font(.system(.body, design: .monospaced)).padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1)))
                if !description.isEmpty { Text(description).font(.caption).foregroundColor(.secondary).padding(.horizontal, 4) }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(NSColor.separatorColor), lineWidth: 1)))
    }
}

struct QRCodeCard: View {
    let wifiName: String; let password: String; @Binding var qrCodeImage: NSImage?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("QR Code").font(.headline); Spacer()
                Button("Copy QR Code") { if let img = qrCodeImage { let pb = NSPasteboard.general; pb.clearContents(); pb.writeObjects([img]) } }
                    .buttonStyle(.bordered).controlSize(.small)
            }
            VStack(spacing: 12) {
                if let qrImage = qrCodeImage {
                    Image(nsImage: qrImage).interpolation(.none).resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200).background(Color.white).cornerRadius(12).shadow(radius: 5)
                    Text("Scan with your phone to connect").font(.caption).foregroundColor(.secondary)
                } else {
                    RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)).frame(width: 200, height: 200)
                        .overlay(Text("Generating...").foregroundColor(.secondary))
                }
            }.frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(NSColor.separatorColor), lineWidth: 1)))
    }
}
