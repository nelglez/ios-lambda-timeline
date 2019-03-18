//
//  ImagePostViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import Photos

class ImagePostViewController: ShiftableViewController {
    
    @IBOutlet weak var zoomBlurSlider: UISlider!
    @IBOutlet weak var hueSlider: UISlider!
    
    
    let zoomBlur = CIFilter(name: "CIZoomBlur")!
    let hueAdjust = CIFilter(name: "CIHueAdjust")!
    
    let context = CIContext(options: nil)
    
    var originalImage: UIImage? {
        didSet {
            updateImageView()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImageViewHeight(with: 1.0)
        
        updateViews()
    }
    
    func updateImageView() {
        
        if let zoomedImage = originalImage {
            imageView.image = zoomBlur(to: zoomedImage)
            imageView.image = hueAdjust(with: zoomedImage)
            
        }
        
    }
    
    
    func updateViews() {
        
        guard let imageData = imageData,
            let image = UIImage(data: imageData) else {
                title = "New Post"
                return
        }
        
        title = post?.title
        
        setImageViewHeight(with: image.ratio)
        
        imageView.image = image
        
        chooseImageButton.setTitle("", for: [])
        
    }
    
   private func zoomBlur(to image: UIImage) -> UIImage {
    
    guard let cgImage = image.cgImage else {return image}
    
    let ciImage = CIImage(cgImage: cgImage)
    
    zoomBlur.setValue(ciImage, forKey: "inputImage")
   // zoomBlur.setValue(CIVector(x: 150, y: 150), forKey: "inputCenter")
    zoomBlur.setValue(zoomBlurSlider.value, forKey: "inputAmount")
    
    guard let outputCIImage = zoomBlur.outputImage else {return image}
    
    //take the ciimage and run it through the CIcontext to create a tangible CGImage
    guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {return image}
    

    
    return UIImage(cgImage: outputCGImage)
    
    }
    
    private func hueAdjust(with image: UIImage) -> UIImage {
        
        guard let cgImage = image.cgImage else {return image}
        
        let ciImage = CIImage(cgImage: cgImage)
        
        hueAdjust.setValue(ciImage, forKey: "inputImage")
        hueAdjust.setValue(hueSlider.value, forKey: "inputAngle")
        
        guard let outputCIImage = hueAdjust.outputImage else {return image}
        
        //take the ciimage and run it through the CIcontext to create a tangible CGImage
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {return image}
        
        
        
        return UIImage(cgImage: outputCGImage)
        
    }
    
    @IBAction func hueSlider(_ sender: UISlider) {
        updateImageView()
    }
    
    
    private func presentImagePickerController() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentInformationalAlertController(title: "Error", message: "The photo library is unavailable")
            return
        }
        
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        
        imagePicker.sourceType = .photoLibrary

        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func createPost(_ sender: Any) {
        
        view.endEditing(true)
        
        guard let imageData = imageView.image?.jpegData(compressionQuality: 0.1),
            let title = titleTextField.text, title != "" else {
            presentInformationalAlertController(title: "Uh-oh", message: "Make sure that you add a photo and a caption before posting.")
            return
        }
        
        postController.createPost(with: title, ofType: .image, mediaData: imageData, ratio: imageView.image?.ratio) { (success) in
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
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            presentImagePickerController()
        case .notDetermined:
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                guard status == .authorized else {
                    NSLog("User did not authorize access to the photo library")
                    self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
                    return
                }
                
                self.presentImagePickerController()
            }
            
        case .denied:
            self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
        case .restricted:
            self.presentInformationalAlertController(title: "Error", message: "Unable to access the photo library. Your device's restrictions do not allow access.")
            
        }
        presentImagePickerController()
    }
    
    func setImageViewHeight(with aspectRatio: CGFloat) {
        
        imageHeightConstraint.constant = imageView.frame.size.width * aspectRatio
        
        view.layoutSubviews()
    }
    
    @IBAction func zoomBlurSliderPressed(_ sender: UISlider) {
        
        updateImageView()
    }
    
    
    
    var postController: PostController!
    var post: Post?
    var imageData: Data?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIBarButtonItem!
}

extension ImagePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        chooseImageButton.setTitle("", for: [])
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
       // imageView.image = image
        originalImage = image
        
        setImageViewHeight(with: image.ratio)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
