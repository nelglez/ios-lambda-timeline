//
//  RecordAudioViewController.swift
//  LambdaTimeline
//
//  Created by Nelson Gonzalez on 3/19/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation

class RecordAudioViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var play: UIButton!
    
    private var recorder: AVAudioRecorder?
    
    var isRecording: Bool {
        return recorder?.isRecording ?? false
    }
    
     var recordingUrl: URL?
    
    
    private var player: AVAudioPlayer?

    var isPlaying: Bool {
        return player?.isPlaying ?? false
    }
    
    var post: Post!
    var postController: PostController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    private func updateButtons() {
        
        let playButtonTitle = isPlaying ? "Stop Playing" : "Play"
        play.setTitle(playButtonTitle, for: .normal)
        
        
        let recordButtonTitle = isRecording ? "Stop Recoring" : "Record"
        recordButton.setTitle(recordButtonTitle, for: .normal)
    }
    
    private func newRecordingUrl() -> URL {
        
        let documentsDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        return documentsDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        updateButtons()
        recordingUrl = recorder.url
        
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    
        updateButtons()
    }
    
    
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
       
        if isRecording {
            recorder?.stop()
            
            return
        }
        
        do {
            //Choose the format
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
            recorder = try AVAudioRecorder(url: newRecordingUrl(), format: format)
            recorder?.record()
            recorder?.delegate = self
        } catch {
            NSLog("Unable to start recoring: \(error)")
        }
        
        updateButtons()
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        if isRecording {
            recorder?.stop()
            return
        }
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        guard let recordingUrl = recordingUrl else {return}
        
        if isPlaying {
            player?.stop()
            updateButtons()
            return
        }
  
        do {
            
            player = try AVAudioPlayer(contentsOf: recordingUrl)
            
            player?.play()
            
            player?.delegate = self
        } catch {
            NSLog("Error attmepting to start playing audio: \(error)")
        }
        
        updateButtons()
        
    }
    

    
    @IBAction func sendRecodingToDatabaseButtonPressed(_ sender: UIButton) {
        
        guard let audioURL = recorder?.url else { return }
        
        postController.addAudioComment(with: audioURL, to: post)
        
        dismiss(animated: true, completion: nil)
        
    }
    
}
