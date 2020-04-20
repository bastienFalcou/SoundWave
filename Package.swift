// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "SoundWave",    
    platforms: [
      .iOS(.v10)
    ],
    products: [        
        .library(name: "SoundWave", targets: ["SoundWave"]),
    ],
    targets: [     
        .target(name: "SoundWave", path: "SoundWave/Classes"),
    ]
)