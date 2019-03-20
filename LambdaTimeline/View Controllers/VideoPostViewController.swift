//
//  VideoPostViewController.swift
//  LambdaTimeline
//
//  Created by Nelson Gonzalez on 3/20/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPostViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet weak var cameraPreviewView: CameraPreviewView!
    @IBOutlet weak var recordButton: UIButton!
    
    
    var postController: PostController?
    var post: Post?
    
    private var captureSession: AVCaptureSession!
    private var recordOutput: AVCaptureMovieFileOutput!
    private var lastRecordedURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }

    
    //the recording gets output on a background queue
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            self.updateViews()
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        DispatchQueue.main.async {
            
            defer {self.updateViews()}
            self.lastRecordedURL = outputFileURL
        }
    }
    
    
    func setupCaptureSession() {
        
        let captureSession = AVCaptureSession()
       
        let cameraDevice = bestCamera()
        
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {return}
        
        guard let cameraDeviceInput = try? AVCaptureDeviceInput(device: cameraDevice), /* guard */ captureSession.canAddInput(cameraDeviceInput) else {
            fatalError("Unable to create camera input")
        }
        
        guard let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice) else {return}
        captureSession.addInput(cameraDeviceInput)
        captureSession.addInput(audioDeviceInput)
        
        
        let fileOutput = AVCaptureMovieFileOutput()
        
        guard captureSession.canAddOutput(fileOutput) else {
            fatalError("Unable to add movie file output to capture session")
        }
        captureSession.addOutput(fileOutput)
   
        captureSession.sessionPreset = .hd1920x1080
       
        captureSession.commitConfiguration()//lock in the
        
        self.captureSession = captureSession
        self.recordOutput = fileOutput
        cameraPreviewView.videoPreviewLayer.session = captureSession
        
    }
    
    private func bestCamera() -> AVCaptureDevice {
        //the users device has a dual camera
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return device
        } else  if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            //single camera on users device
            return device
            
        } else {
            fatalError("Missing expected back camera on device")
        }
        
    }
    
    private func updateViews() {
        
        let isRecording = recordOutput.isRecording
        
        let recordButtonImage = isRecording ? "Stop" : "Record"
        recordButton.setImage(UIImage(named: recordButtonImage), for: .normal)
        
    }
    
    private func newRecordingURL() -> URL {
        
        let documentDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        return documentDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
    }

   
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        
        if recordOutput.isRecording {
            recordOutput.stopRecording()
        } else {
        recordOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
        }
        
        
    }
    
    @IBAction func uploadVideoBarButtonPressed(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "Add Video Post", message: nil, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Title"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Post Now", style: .default) { (_) in
            guard let title = alert.textFields?[0].text, title.count > 0 else {
                self.presentInformationalAlertController(title: "Uh-oh", message: "Make sure that you add a photo and a caption before posting.")
                return
            }
            
             guard let url = self.lastRecordedURL, let data = try? Data(contentsOf: url) else { return }
        
            self.postController?.createPost(with: title, ofType: .video, mediaData: data, ratio: 9.0/16.0) { (success) in
                guard success else {
                    DispatchQueue.main.async {
                        self.presentInformationalAlertController(title: "Error", message: "Unable to create post. Try again.")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        })
        
        present(alert, animated: true, completion: nil)
    
    }
}
