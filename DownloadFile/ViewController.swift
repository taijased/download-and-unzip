//
//  ViewController.swift
//  DownloadFile
//
//  Created by Maxim Spiridonov on 18/03/2019.
//  Copyright © 2019 Maxim Spiridonov. All rights reserved.
//

import UIKit
import UserNotifications
import ZIPFoundation


class ViewController: UIViewController {
    
    private var alert: UIAlertController!
    private let dataProvider = DataProvider()
    private var filePath: String?
    private var fileSavePath: URL?
    
    
    @IBAction func downloadTap(_ sender: UIButton) {
        showAlert()
        dataProvider.startDownload()
    }
    
    @IBOutlet weak var unzipOutletButton: UIButton! {
        didSet {
            unzipOutletButton.isHidden = true
        }
    }
    
    
    @IBAction func unzipButton(_ sender: UIButton) {
        unzipFile()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForNotification()
        
        dataProvider.fileLocation = { (location) in
            
            // Сохранить файл для дальнейшего использования
            print("Download finished: \(location.absoluteString)")
            self.filePath = location.absoluteString
            self.alert.dismiss(animated: false, completion: nil)
            self.postNotification()
            self.unzipOutletButton.isHidden = false
        }
        
    }
    
    
    
    private func unzipFile() {
        
        let fileManager = FileManager()
        
        var separatorPath = filePath!.components(separatedBy: "/")
        let directoryName = separatorPath[separatorPath.count - 1].components(separatedBy: ".")[0]
        let fileName = separatorPath[separatorPath.count - 1]
        separatorPath.remove(at: separatorPath.count - 1)

        let currentWorkingPath = String(separatorPath.joined(separator: "/"))
        

        var sourceURL = URL(fileURLWithPath: currentWorkingPath)
        sourceURL.appendPathComponent(fileName)

        var destinationURL = URL(fileURLWithPath: currentWorkingPath)
        destinationURL.appendPathComponent(directoryName)
        

        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: sourceURL, to: destinationURL)

            self.postNotification(path: destinationURL.absoluteString, fileName: fileName)
            
        } catch {
            print("Extraction of ZIP archive failed with error:\(error.localizedDescription)")
        }
    }

    private func showAlert() {
        
        alert = UIAlertController(title: "Downloading...", message: "0%", preferredStyle: .alert)
        
        let height = NSLayoutConstraint(item: alert.view,
                                        attribute: .height,
                                        relatedBy: .equal,
                                        toItem: nil,
                                        attribute: .notAnAttribute,
                                        multiplier: 0,
                                        constant: 170)
        
        alert.view.addConstraint(height)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (action) in
            
            self.dataProvider.stopDownload()
        }
        
        alert.addAction(cancelAction)
        present(alert, animated: true) {
            
            let size = CGSize(width: 40, height: 40)
            let point = CGPoint(x: self.alert.view.frame.width / 2 - size.width / 2,
                                y: self.alert.view.frame.height / 2 - size.height / 2)
            
            let activityIndicator = UIActivityIndicatorView(frame: CGRect(origin: point, size: size))
            activityIndicator.color = .gray
            activityIndicator.startAnimating()
            
            let progressView = UIProgressView(frame: CGRect(x: 0,
                                                            y: self.alert.view.frame.height - 44,
                                                            width: self.alert.view.frame.width,
                                                            height: 2))
            progressView.tintColor = .blue
            
            self.dataProvider.onProgress = { (progress) in
                
                progressView.progress = Float(progress)
                self.alert.message = String(Int(progress * 100)) + "%"
            }
            
            self.alert.view.addSubview(activityIndicator)
            self.alert.view.addSubview(progressView)
        }
    }
}

extension ViewController {
    
    private func registerForNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (_, _) in
            
        }
    }
    
    private func postNotification() {
        
        let content = UNMutableNotificationContent()
        content.title = "Download complete!"
        content.body = "Your background transfer has completed. File path: \(filePath!)"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        
        let request = UNNotificationRequest(identifier: "TransferComplete", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    private func postNotification(path: String, fileName: String) {
        
        let content = UNMutableNotificationContent()
        content.title = "Unzip complete!"
        content.body = "Unzip file \(fileName). Files path: \(path)"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let request = UNNotificationRequest(identifier: "TransferComplete", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

