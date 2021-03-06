//
//  AssistantViewController.swift
//  MacAssistant
//
//  Created by Vansh Gandhi on 8/3/18.
//  Copyright © 2018 Vansh Gandhi. All rights reserved.
//

import Cocoa
import Log
import SwiftGRPC
import WebKit

class AssistantViewController: NSViewController, AssistantDelegate, AudioDelegate, NSCollectionViewDataSource {
    
    let Log = Logger()
    let assistant = Assistant()
    var conversation: [ConversationEntry] = []
    var currentAssistantCall: AssistCall?
    lazy var audioEngine = AudioEngine(delegate: self)
    let conversationItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "ConversationItem")


    @IBOutlet weak var initialPromptLabel: NSTextField!
    @IBOutlet weak var conversationCollectionView: NSCollectionView!
    @IBOutlet weak var keyboardInputField: NSTextField!
    
    override func viewDidLoad() {
        conversationCollectionView.dataSource = self
        let conversationItemNib = NSNib(nibNamed: NSNib.Name(rawValue: "ConversationItem"), bundle: nil)
        conversationCollectionView.register(conversationItemNib, forItemWithIdentifier: conversationItemIdentifier)
    }

    @IBAction func onEnterClicked(_ sender: Any) {
        let query = keyboardInputField.stringValue
        if query.isNotEmpty {
            conversation.append(ConversationEntry(isFromUser: true, text: query))
            conversationCollectionView.reloadData()
            assistant.sendTextQuery(text: query, delegate: self)
            keyboardInputField.stringValue = ""
        }
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return conversation.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let entry = conversation[indexPath.item]
        let alignment = entry.isFromUser ? NSTextAlignment.right : NSTextAlignment.left
        let item = collectionView.makeItem(withIdentifier: conversationItemIdentifier, for: indexPath)
        item.textField?.stringValue = entry.text
        item.textField?.alignment = alignment
        return item
    }

    // TODO: supplementalView to display screen out?

    func onAssistantCallCompleted(result: CallResult) {
        currentAssistantCall = nil
        
        if !result.success {
            // TODO: show error (Create ErrorConversationEntry)
        }
        
        Log.debug(result.description)
        if let statusMessage = result.statusMessage {
            Log.debug(statusMessage)
        }
    }
    
    func onDoneListening() {
        audioEngine.stopRecording()
    }
    
    func onDisplayText(text: String) {
        conversation.append(ConversationEntry(isFromUser: false, text: text))
        conversationCollectionView.reloadData()
    }
    
    func onScreenOut(htmlData: String) {

    }
    
    func onTranscriptUpdate(transcript: String) {
        Log.debug("Transcript update: \(transcript)")
    }
    
    func onAudioOut(audio: Data) {
        Log.debug("Got audio")
        audioEngine.playAudio(data: audio)
    }
    
    func onFollowUpRequired() {
        Log.debug("Follow up needed")
        // TODO: Start listening again (or ask for typing prompt again if they typed?)
    }
    
    func onError(error: Error) {
        Log.error("Got error \(error.localizedDescription)")
    }
    
    func onMicrophoneInputAudio(audioData: Data) {
        if let call = currentAssistantCall {
            assistant.sendAudioChunk(streamCall: call, audio: audioData, delegate: self)
        }
    }
}
