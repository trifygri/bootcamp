/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Contains the object recognition view controller for the Breakfast Finder.
 */

import UIKit
import AVFoundation
import SwiftUI
import VideoToolbox
// 0. import Vision framework
import Vision


final class CameraUIViewController: CameraViewController {
    private var detectionOverlay: CALayer! = nil
    weak var updateBeansDelegate: CoffeeBeanUpdateDelegate?
    var captureImage: Bool = false
    var coffeeBeans: [CoffeeBean] = []
    var pause: Bool = false

    // add requests
    private var requests = [VNRequest]()

    

    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        let imageFeature = VNGenerateImageFeaturePrintRequest() { (request, error) in
            if let result =  request.results?.first as? VNFeaturePrintObservation {
                //1. Compute distances
                
                DispatchQueue.main.async(execute: {
                   // 2. Update UI
                })
                
            }
            
        }
        
        self.requests = [imageFeature]
        
        return error
    }
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if pause{
            return
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        if captureImage {
            
            do {
                captureImage = false
                updateBeansDelegate?.disableCapture()
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let image = UIImage(ciImage: ciImage, scale: 1.0, orientation: .right)
                let imageId = UUID().uuidString
                if let data = image.pngData() {
                    try data.write(to: FileManager.documentsUrl.appendingPathComponent(imageId).appendingPathExtension("png"))
                    let coffeeId = UUID().uuidString
                    DispatchQueue.main.async(execute: {
                        let diaryEntry = DiaryEntry(date: Date(), grindSize: 15.0, temperature: 95.0, quality: 3)
                        let coffeeBean = CoffeeBean(id: coffeeId, name: "New Entry", diaryEntries: [diaryEntry], image: imageId + ".png")
                        self.updateBeansDelegate?.addNewBean(coffeeBean)
                        
                    })
                }
            } catch let error {
                print(error)
            }
        } else {
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
            
            do {
                try imageRequestHandler.perform(self.requests)
            } catch {
                print(error)
            }
        }
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        setupVision()
        startCaptureSession()
    }
    
    
    
}

protocol CoffeeBeanUpdateDelegate: class {
    func updateSelectedBean(_ bean: CoffeeBean)
    func addNewBean(_ bean: CoffeeBean)
    func updateTopBean(_ bean: CoffeeBean)
    func disableCapture()
}

struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var coffeeBeansCollection: CoffeeBeanCollection
    @Binding var addNewBagOfBeans: Bool
    @Binding var showSelectedBean: Bool
    
    class Coordinator: CoffeeBeanUpdateDelegate {
        
        
        var parent: CameraViewControllerRepresentable
        
        init(_ parent: CameraViewControllerRepresentable) {
            self.parent = parent
        }
        
        func addNewBean(_ bean: CoffeeBean) {
            parent.coffeeBeansCollection.coffeeBeans.append(bean)
            parent.coffeeBeansCollection.selectedBean = bean
            parent.showSelectedBean = true
        }
        
        
        func updateSelectedBean(_ bean: CoffeeBean) {
            // 3. update selected bean and show it
        }
        
        func updateTopBean(_ bean: CoffeeBean) {
            // 4. updated top bean
        }
        
        
        
        func disableCapture() {
            parent.addNewBagOfBeans = false
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIViewController(context: Context) -> CameraUIViewController {
        let vc = CameraUIViewController()
        vc.updateBeansDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ viewController: CameraUIViewController, context: Context) {
        viewController.captureImage = addNewBagOfBeans
        viewController.coffeeBeans = coffeeBeansCollection.coffeeBeans
        viewController.pause = showSelectedBean
    }
}

func featureprintObservationForImage(cgImage: CGImage) -> VNFeaturePrintObservation? {
    let requestHandler = VNImageRequestHandler(cgImage: cgImage,  options: [:])
    let request = VNGenerateImageFeaturePrintRequest()
    do {
        try requestHandler.perform([request])
        return request.results?.first as? VNFeaturePrintObservation
    } catch {
        print("Vision error: \(error)")
        return nil
    }
}
