//
//  CameraManager.swift
//  iCameraStreamer
//
//  Created by Levent Tasdemir on 04.04.23.
//

import Cocoa
import AVFoundation

class CameraManager: NSObject {
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureSession: AVCaptureSession!
    private var captureDevice: AVCaptureDevice!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var availableCaptuteDevices: [AVCaptureDevice]!
    
    private let containerView: NSView
    private let cameraQueue: DispatchQueue
    
    weak var captuteDelegate: CameraCaptureDelegate?
    
    public var captuteDevices: [AVCaptureDevice] {
        get { return availableCaptuteDevices }
    }
    
    init(containerView: NSView) throws {
        self.containerView = containerView
        cameraQueue = DispatchQueue(label: "sample buffer delegate", attributes: [])
        super.init()
        try updateAvailableDevicesList()
    }
    
    deinit {
        previewLayer = nil
        captureSession = nil
        captureDevice = nil
    }
    
    public func prepareSelectedDevice(captureDevice: AVCaptureDevice) throws {
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                throw CameraError.cannotAddInput
            }
            
            if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            } else {
                throw CameraError.previewLayerConnectionError
            }
            
            previewLayer.frame = containerView.bounds
            containerView.layer = previewLayer
            containerView.wantsLayer = true
        } catch {
            throw CameraError.cannotDetectCameraDevice
        }
        
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: cameraQueue)
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        } else {
            throw CameraError.cannotAddOutput
        }
    }
    
    public func startSession() throws {
        if let videoSession = captureSession {
            if !videoSession.isRunning {
                cameraQueue.async {
                    videoSession.startRunning()
                }
            }
        } else {
            throw CameraError.videoSessionNil
        }
    }
    
    public func stopSession() throws {
        if let videoSession = captureSession {
            if videoSession.isRunning {
                cameraQueue.async {
                    videoSession.stopRunning()
                }
            }
        } else {
            throw CameraError.videoSessionNil
        }
    }
    
    private func updateAvailableDevicesList() throws {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .deskViewCamera, .externalUnknown], mediaType: .video, position: .unspecified)
        
        availableCaptuteDevices = discoverySession.devices
        for device in availableCaptuteDevices {
            print(device.localizedName)
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        captuteDelegate?.captureVideoOutput(sampleBuffer: sampleBuffer)
    }
}

typealias CameraCaptureOutput = AVCaptureOutput
typealias CameraSampleBuffer = CMSampleBuffer
typealias CameraCaptureConnection = AVCaptureConnection

protocol CameraCaptureDelegate: AnyObject {
    func captureVideoOutput(sampleBuffer: CMSampleBuffer)
}

enum CameraError: LocalizedError {
  case cannotDetectCameraDevice
  case cannotAddInput
  case previewLayerConnectionError
  case cannotAddOutput
  case videoSessionNil
  
  var localizedDescription: String {
    switch self {
    case .cannotDetectCameraDevice: return "Cannot detect camera device"
    case .cannotAddInput: return "Cannot add camera input"
    case .previewLayerConnectionError: return "Preview layer connection error"
    case .cannotAddOutput: return "Cannot add video output"
    case .videoSessionNil: return "Camera video session is nil"
    }
  }
}
