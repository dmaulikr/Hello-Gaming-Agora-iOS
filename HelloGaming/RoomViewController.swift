//
//  RoomViewController.swift
//
//  Created by GongYuhua on 16/8/22.
//  Copyright © 2016年 Agora. All rights reserved.
//

import UIKit

protocol RoomVCDelegate: class {
    func roomVCNeedClose(_ roomVC: RoomViewController)
}

class RoomViewController: UIViewController {
    
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var logTableView: UITableView!
    @IBOutlet weak var muteAudioButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    
    var roomName: String!
    weak var delegate: RoomVCDelegate?
    
    fileprivate var agoraKit: AgoraRtcEngineKitForGaming!
    
    fileprivate var logs = [String]()
    
    fileprivate var audioMuted = false {
        didSet {
            muteAudioButton?.setImage(UIImage(named: audioMuted ? "btn_mute_blue" : "btn_mute"), for: UIControlState())
            agoraKit.muteLocalAudioStream(audioMuted)
        }
    }
    
    fileprivate var speakerEnabled = true {
        didSet {
            speakerButton?.setImage(UIImage(named: speakerEnabled ? "btn_speaker_blue" : "btn_speaker"), for: UIControlState())
            speakerButton?.setImage(UIImage(named: speakerEnabled ? "btn_speaker" : "btn_speaker_blue"), for: .highlighted)
            
            agoraKit.setEnableSpeakerphone(speakerEnabled)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomNameLabel.text = "\(roomName!)"
        logTableView.rowHeight = UITableViewAutomaticDimension
        logTableView.estimatedRowHeight = 25
        
        joinChannel()
    }
    
    @IBAction func doMuteAudioPressed(_ sender: UIButton) {
        audioMuted = !audioMuted
    }
    
    @IBAction func doSpeakerPressed(_ sender: UIButton) {
        speakerEnabled = !speakerEnabled
    }
    
    @IBAction func doClosePressed(_ sender: UIButton) {
        leaveChannel()
    }
    
    func loadAgoraKit() {
        agoraKit = AgoraRtcEngineKitForGaming.sharedEngine(withAppId: KeyCenter.AppId, delegate: self)
        agoraKit.setChannelProfile(AgoraRtcChannelProfile.channelProfile_Game_Free_Mode)
    }
}

private extension RoomViewController {
    func append(log string: String) {
        guard !string.isEmpty else {
            return
        }
        
        logs.append(string)
        
        var deleted: String?
        if logs.count > 200 {
            deleted = logs.removeFirst()
        }
        
        updateLogTable(withDeleted: deleted)
    }
    
    func updateLogTable(withDeleted deleted: String?) {
        guard let tableView = logTableView else {
            return
        }
        
        let insertIndexPath = IndexPath(row: logs.count - 1, section: 0)
        
        tableView.beginUpdates()
        if deleted != nil {
            tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
        tableView.insertRows(at: [insertIndexPath], with: .none)
        tableView.endUpdates()
        
        tableView.scrollToRow(at: insertIndexPath, at: .bottom, animated: false)
    }
}

//MARK: - table view
extension RoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath) as! LogCell
        cell.set(log: logs[(indexPath as NSIndexPath).row])
        return cell
    }
}

//MARK: - engine
private extension RoomViewController {
    func joinChannel() {
        // workaround/waiting SDK initialize
        sleep(1)
        
        let code = agoraKit.joinChannel(roomName, info: nil, uid: 0)

        if code != 0 {
            DispatchQueue.main.async(execute: {
                self.append(log: "Join channel failed: \(code)")
            })
        }
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel()
        delegate?.roomVCNeedClose(self)
    }
}

extension RoomViewController: AgoraRtcEngineKitForGamingDelegate {
    func rtcEngineConnectionDidInterrupted(_ engine: AgoraRtcEngineKitForGaming!) {
        append(log: "Connection Interrupted")
    }

    func rtcEngineConnectionDidLost(_ engine: AgoraRtcEngineKitForGaming!) {
        append(log: "Connection Lost")
    }

    func rtcEngineRequestChannelKey(_ engine: AgoraRtcEngineKitForGaming!) {
        append(log: "rtcEngineRequestChannelKey")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKitForGaming!, didOccurError errorCode: AgoraRtcErrorCode) {
        append(log: "Occur error: \(errorCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKitForGaming!, didJoinChannel channel: String!, withUid uid: UInt, elapsed: Int) {
        append(log: "Did joined channel: \(channel!), with uid: \(uid), elapsed: \(elapsed)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKitForGaming!, didJoinedOfUid uid: UInt, elapsed: Int) {
        append(log: "Did joined of uid: \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKitForGaming!, didOfflineOfUid uid: UInt, reason: AgoraRtcUserOfflineReason) {
        append(log: "Did offline of uid: \(uid), reason: \(reason.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKitForGaming!, audioQualityOfUid uid: UInt, quality: AgoraRtcQuality, delay: UInt, lost: UInt) {
        append(log: "Audio Quality of uid: \(uid), quality: \(quality.rawValue), delay: \(delay), lost: \(lost)")
    }
}
