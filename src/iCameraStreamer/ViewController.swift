//
//  ViewController.swift
//  iCameraStreamer
//
//  Created by Levent Tasdemir on 04.04.23.
//

import Cocoa

class ViewController: NSViewController, NSComboBoxDelegate, CameraManagerDelegate {
    func cameraManager(_ output: CameraCaptureOutput, didOutput sampleBuffer: CameraSampleBuffer, from connection: CameraCaptureConnection) {
        
    }
    
    @IBOutlet weak var captureDevicesCombobox: NSComboBox!
    private var cameraManager: CameraManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        do {
            cameraManager = try CameraManager(containerView: view)
            cameraManager.delegate = self
            for device in cameraManager.captuteDevices {
                captureDevicesCombobox.addItem(withObjectValue: device.localizedName)
            }
            
            captureDevicesCombobox.delegate = self
        } catch {
            print(error.localizedDescription)
        }
    }
    
    internal func comboBoxSelectionDidChange(_ notification: Notification) {
        do {
            try cameraManager.prepareSelectedDevice(captureDevice: cameraManager.captuteDevices[captureDevicesCombobox.indexOfSelectedItem])
            
            try cameraManager.startSession()
            captureDevicesCombobox.isHidden = true
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func viewDidDisappear() {
      super.viewDidDisappear()
      do {
        try cameraManager.stopSession()
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
}

