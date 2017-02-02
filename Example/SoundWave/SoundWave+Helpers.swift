//
//  SoundWave+Helpers.swift
//  SoundWave
//
//  Created by Bastien Falcou on 12/6/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

extension URL {
    static func checkPath(_ path: String) -> Bool {
        let isFileExist = FileManager.default.fileExists(atPath: path)
        return isFileExist
    }
	
	static func documentsPath(forFileName fileName: String) -> URL? {
		let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
		let writePath = URL(string: documents)!.appendingPathComponent(fileName)
		
		var directory: ObjCBool = ObjCBool(false)
		if FileManager.default.fileExists(atPath: documents, isDirectory:&directory) {
			return directory.boolValue ? writePath : nil
		}
		return nil
	}
}

extension UIViewController {
	func showAlert(with error: Error) {
		let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
			alertController.dismiss(animated: true, completion: nil)
		})
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
	}
}

extension UIColor {
	static var mainBackgroundPurple: UIColor {
		return UIColor(red: 61.0 / 255.0, green: 28.0 / 255.0, blue: 105.0 / 255.0, alpha: 1.0)
	}
	
	static var audioVisualizationPurpleGradientStart: UIColor {
		return UIColor(red: 76.0 / 255.0, green: 62.0 / 255.0, blue: 127.0 / 255.0, alpha: 1.0)
	}
	
	static var audioVisualizationPurpleGradientEnd: UIColor {
		return UIColor(red: 133.0 / 255.0, green: 112.0 / 255.0, blue: 190.0 / 255.0, alpha: 1.0)
	}
	
	static var mainBackgroundGray: UIColor {
		return UIColor(red: 193.0 / 255.0, green: 188.0 / 255.0, blue: 167.0 / 255.0, alpha: 1.0)
	}
	
	static var audioVisualizationGrayGradientStart: UIColor {
		return UIColor(red: 130.0 / 255.0, green: 135.0 / 255.0, blue: 115.0 / 255.0, alpha: 1.0)
	}
	
	static var audioVisualizationGrayGradientEnd: UIColor {
		return UIColor(red: 83.0 / 255.0, green: 85.0 / 255.0, blue: 71.0 / 255.0, alpha: 1.0)
	}
}
