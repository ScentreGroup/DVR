import Foundation

//    private func persist(_ interactions: [Interaction]) {
//        defer {
//            abort()
//        }

// Create directory
//        let outputDirectory = (self.outputDirectory as NSString).expandingTildeInPath
//        let fileManager = FileManager.default
//        if !fileManager.fileExists(atPath: outputDirectory) {
//            do {
//              try fileManager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)
//            } catch {
//              print("[DVR] Failed to create cassettes directory.")
//            }
//        }

//        let cassette = Cassette(name: cassetteName, interactions: interactions)

// Persist


//        do {
//            let outputPath = ((outputDirectory as NSString).appendingPathComponent(cassetteName) as NSString).appendingPathExtension("json")!
//            let data = try JSONSerialization.data(withJSONObject: cassette.dictionary, options: [.prettyPrinted])
//
//            // Add trailing new line
//            guard var string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
//                print("[DVR] Failed to persist cassette.")
//                return
//            }
//            string = string.appending("\n") as NSString
//
//            if let data = string.data(using: String.Encoding.utf8.rawValue) {
//                try? data.write(to: URL(fileURLWithPath: outputPath), options: [.atomic])
//                print("[DVR] Persisted cassette at \(outputPath). Please add this file to your test target")
//                return
//            }
//
//            print("[DVR] Failed to persist cassette.")
//        } catch {
//            print("[DVR] Failed to persist cassette.")
//        }
//    }
