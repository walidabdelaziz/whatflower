//
//  ViewController.swift
//  whatflower
//
//  Created by Walid  on 8/10/20.
//  Copyright © 2020 Walid . All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var label: UILabel!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    

    
    
    
    let imagePicker = UIImagePickerController()

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else{
                fatalError("Cannot convert UIImage into CIImage")

            }
            detect(ciImage)

        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(_ image: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifer().model) else{
            fatalError("Error while loading the model")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results?.first as? VNClassificationObservation else{
                fatalError("Error while requesting reuslts")
            }
            self.navigationItem.title = results.identifier.capitalized
            self.performRequest(flowerName: results.identifier)
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do{
        try handler.perform([request])
        }catch{
            print(error)
        }
    }
    
    func performRequest(flowerName:String){
        
        let parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : flowerName,
        "indexpageids" : "",
        "redirects" : "1",
        "pithumbsize" : "500"
        ]
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess{
                print(response)
                
                let flowerJson:JSON = JSON(response.result.value!)
                
                let pageid = flowerJson["query"]["pageids"][0].stringValue
                
                let flowerDescroption = flowerJson["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageUrl = flowerJson["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageUrl))
                self.label.text = flowerDescroption
            }
        }
    }

    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}

