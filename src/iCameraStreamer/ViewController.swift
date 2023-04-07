//
//  ViewController.swift
//  iCameraStreamer
//
//  Created by Levent Tasdemir on 04.04.23.
//

import Cocoa
import AVFoundation
import CocoaMQTT

class ViewController: NSViewController, NSComboBoxDelegate, CameraCaptureDelegate {
    
    @IBOutlet weak var captureDevicesCombobox: NSComboBox!
    private var cameraManager: CameraManager!
    private var mqtt5: CocoaMQTT5!
    private var clientID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        do {
            cameraManager = try CameraManager(containerView: view)
            cameraManager.captuteDelegate = self
            for device in cameraManager.captuteDevices {
                captureDevicesCombobox.addItem(withObjectValue: device.localizedName)
            }
            
            captureDevicesCombobox.delegate = self
            connectMqtt()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func connectMqtt() {
        clientID = "iCameraStreamer-" + String(ProcessInfo().processIdentifier)
        mqtt5 = CocoaMQTT5(clientID: clientID, host: "localhost", port: 1883)
    }
    
    private func sendMqtt() {
        if mqtt5.connect() == false {
            print("Not connected")
        }
    }
    
    internal func comboBoxSelectionDidChange(_ notification: Notification) {
        do {
            try cameraManager.prepareSelectedDevice(captureDevice: cameraManager.captuteDevices[captureDevicesCombobox.indexOfSelectedItem])
            
            try cameraManager.startSession()
            captureDevicesCombobox.isHidden = true
            sendMqtt()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func viewDidDisappear() {
      super.viewDidDisappear()
      do {
        try cameraManager.stopSession()
          mqtt5?.disconnect()
      } catch {
        // Cath the error here
        print(error.localizedDescription)
      }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private var count: Int = 0
    func captureVideoOutput(sampleBuffer: CMSampleBuffer) {
        autoreleasepool {
            guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let width = CVPixelBufferGetWidth(cvBuffer)
            let height = CVPixelBufferGetHeight(cvBuffer)
            let ciImage = CIImage(cvImageBuffer: cvBuffer)
            let context = CIContext(options: nil)
            guard let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: width, height: height)) else { return }
            let nsImage = NSImage(cgImage: cgImage, size: CGSize(width: width, height: height))
        
            guard let compressedImage = nsImage.toJpg(compressionRatio: 0.6) else { return }
            var array = [UInt8](repeating: 0, count: compressedImage.count)
            let nsData = NSData(data: compressedImage)
            nsData.getBytes(&array, length: nsData.length)
            mqtt5.publish(CocoaMQTT5Message(topic: clientID + "/image", payload: array, qos: .qos1), DUP: true, retained: false, properties: MqttPublishProperties())
            
        }
    }
}

extension NSImage {
    func toJpg(compressionRatio: Float) -> Data? {
        guard let tiff = self.tiffRepresentation, let imageRep = NSBitmapImageRep(data: tiff) else { return nil }
        return imageRep.representation(using: .jpeg, properties: [.compressionFactor : compressionRatio])!
    }
}

