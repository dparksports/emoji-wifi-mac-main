#!/usr/bin/swift

import Cocoa
import AVFoundation
import CoreImage
import CoreWLAN

// Define CameraPreviewView first
class CameraPreviewView: NSView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        previewLayer = layer
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill
        layer.backgroundColor = NSColor.black.cgColor
        layer.cornerRadius = 8
        layer.masksToBounds = true
        self.layer?.addSublayer(layer)
    }
}

// Main AppDelegate class
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    var window: NSWindow!
    var captureSession: AVCaptureSession?
    var videoOutput: AVCaptureVideoDataOutput?
    var textField: NSTextField!
    var ssid: String?
    var password: String?
    var previewView: CameraPreviewView!
    
    // Action methods must be defined BEFORE they're used in UI setup
    @objc func scanQR(_ sender: NSButton) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else {
                DispatchQueue.main.async {
                    self?.textField.stringValue = "Camera access denied"
                }
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                self?.startCamera()
            }
        }
    }
    
    @objc func joinWiFi(_ sender:NSButton) {
        let interface: String = "en0"
        let task = Process()
        let pipe = Pipe()
        
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-setairportnetwork", interface, self.ssid!, self.password!]
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                print("Output: \(output)")
            }
            
            if task.terminationStatus == 0 {
                textField.stringValue = "✅ Successfully joined network: \(ssid!)!"
            } else {
                textField.stringValue = "❌ Failed to join network. Exit code: \(task.terminationStatus)"
                return
            }
        } catch {
            textField.stringValue = "⚠️ Error running networksetup: \(error)"
            return
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Window setup
        window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 500, height: 450),
                          styleMask: [.titled, .closable],
                          backing: .buffered,
                          defer: false)
        window.title = "QR Scanner"
        window.delegate = self
        
        // Create preview view - ADJUSTED TO AVOID CLIPPING
        previewView = CameraPreviewView(frame: NSRect(x: 20, y: 90, width: 460, height: 290))
        window.contentView?.addSubview(previewView)
        
        // Create container for bottom controls
        let controlContainer = NSView(frame: NSRect(x: 20, y: 380, width: 460, height: 70))
        window.contentView?.addSubview(controlContainer)
        
        // Add text field first (at the top)
        textField = NSTextField(frame: NSRect(x: 20, y: 35, width: 420, height: 30))
        textField.stringValue = "Click 'Scan' to detect QR codes"
        textField.isEditable = false
        textField.alignment = .center
        controlContainer.addSubview(textField)
        
        // Add buttons below the text field
        let scanButton = NSButton(frame: NSRect(x: 40, y: 5, width: 100, height: 30))
        scanButton.title = "Scan"
        scanButton.target = self
        scanButton.action = #selector(scanQR(_:))
        controlContainer.addSubview(scanButton)
        
        let joinButton = NSButton(frame: NSRect(x: 160, y: 5, width: 100, height: 30))
        joinButton.title = "Join"
        joinButton.target = self
        joinButton.action = #selector(joinWiFi(_:))
        controlContainer.addSubview(joinButton)
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func startCamera() {
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
              AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            DispatchQueue.main.async {
                self.textField.stringValue = "No camera available"
            }
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCMPixelFormat_32BGRA]
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            // Set up preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            DispatchQueue.main.async {
                self.previewView.setPreviewLayer(previewLayer)
            }
            
            session.commitConfiguration()
            self.captureSession = session
            self.videoOutput = output
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
            session.startRunning()
        } catch {
            DispatchQueue.main.async {
                self.textField.stringValue = "Error setting up camera: \(error.localizedDescription)"
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature],
            let qrFeature = features.first else { return }
        print("Message: \(qrFeature.messageString ?? "N/A")")
        if let payload = qrFeature.messageString {
            self.processQRCode(payload)
            DispatchQueue.main.async {
                self.stopCamera()
            }
            return
        }
    }
   
    func extractSubstring(from input: String) -> String? {
        guard let startRange = input.range(of: "WIFI:S:"),
            let endRange = input.range(of: ";T:", options: .backwards) else {
            return nil
        }
        
        let substringRange = startRange.upperBound..<endRange.lowerBound
        return String(input[substringRange])
    }
    
    func extractPassword(from string: String) -> String? {
        guard let pRange = string.range(of: ";P:") else {
            return nil
        }
        
        let startIndex = pRange.upperBound
        
        guard let endRange = string[startIndex...].range(of: ";") else {
            return nil
        }
        
        let password = string[startIndex..<endRange.lowerBound]
        return String(password)
    }
    
    func convertOptionalToString(_ optional: String?) -> String {
        return optional ?? ""
    }
    
    func parseWiFiQRCode(from payload: String) {
        let localPassword = extractPassword(from: payload) ?? ""
        self.password = localPassword
        self.ssid = extractSubstring(from: payload)
        print("ssid: \(convertOptionalToString(self.ssid))")
        print("password: \(convertOptionalToString(self.password))")
        DispatchQueue.main.async {
            self.textField.stringValue = localPassword
        }
    }
    
    private func processQRCode(_ payload: String) {
        print("payload: \(payload)")
        parseWiFiQRCode(from: payload)
        DispatchQueue.main.async {
            self.stopCamera()
        }
    }
    
    private func stopCamera() {
        captureSession?.stopRunning()
        captureSession = nil
        videoOutput = nil
        previewView.previewLayer?.removeFromSuperlayer()
        previewView.previewLayer = nil
    }
    
    func windowWillClose(_ notification: Notification) {
        stopCamera()
        NSApp.terminate(self)
    }
}

// Start the application
let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()