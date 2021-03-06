//
//  ViewController.swift
//  FileSync
//
//  Created by Joseph McCraw on 1/7/20.
//  Copyright © 2020 Joseph McCraw. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    var images = [UIImage]()
    
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
            case .connected:
                print("Connteted: \(peerID.displayName)")
                
            images = []
            case .connecting:
                print("Connecting: \(peerID.displayName)")
            case .notConnected:
                print("Not Conntected: \(peerID.displayName)")
            @unknown default:
                print("Unknown State Received: \(peerID.displayName)")
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            if let image = UIImage(data: data) {
                    self.images.insert(image, at: 0)
                    self.collectionView.reloadData()
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print(progress)
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ShowBlender FileSync"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPictures))
        
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
        
    }
    
    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect To Others", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Host a Session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a Session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func startHosting(action: UIAlertAction) {
        images = []
//        guard let mcSession = mcSession else { return}
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "sb-filesync", discoveryInfo: nil, session: mcSession)
        title = "FileSync - Host: \(peerID.displayName)"
        mcAdvertiserAssistant?.start()
    }
    
    func joinSession(action: UIAlertAction) {
//        guard let mcSession = mcSession else { return}
        images = []
        let mcBrowser = MCBrowserViewController(serviceType: "sb-filesync", session: mcSession)
        mcBrowser.delegate = self
        
        title = "FileSync - Joined"
        present(mcBrowser, animated: true)
    }
        
        
    @objc func importPictures() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
        
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContentImageView", for: indexPath)
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
        }
        return cell
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        images.insert(image, at: 0) // Or use append to add to bottom of collection
        collectionView?.reloadData()
//        guard let mcSession = mcSession else { return }
        if mcSession.connectedPeers.count > 0 {
            // 2
            if let imageData = image.pngData() {
                // 3
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}

