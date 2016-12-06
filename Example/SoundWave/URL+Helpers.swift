//
//  URL+Helpers.swift
//  SoundWave
//
//  Created by Bastien Falcou on 12/6/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation

extension URL {
	static func checkPath(_ path: String) -> Bool {
		var directory: ObjCBool = ObjCBool(false)
		if FileManager.default.fileExists(atPath: path, isDirectory:&directory) {
			return !directory.boolValue
		}
		return false
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
