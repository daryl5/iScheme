//
//  ClientManager.swift
//  iScheme
//
//  Created by lingwan on 2017/6/25.
//  Copyright © 2017年 lingwan. All rights reserved.
//

import Foundation
import Crashlytics

final class ClientManager {
    static let manager = ClientManager()
    
    private let _configCenter = ConfigCenter.sharedInstance
    
    private var _qr: QRCodeClient
    private var _iOSSim: iOSSimulatorClient
    private var _android: AndroidClient
    
    private var _clients: [Client]
    
    //iOS Simulator + real devices
    var iOSClients: [Client] {
        get {
            var ret: [Client] = [_iOSSim]
            ret.append(contentsOf:_clients.filter { $0 is iOSDeviceClient })
            return ret
        }
    }
    
    init() {
        let qrEnable: Bool = _configCenter.needQRCode.value
        _qr = QRCodeClient.init(name: "QR-code Viewer", state: ClientState.init(booleanLiteral: qrEnable))
        
        let androidEnable: Bool = _configCenter.androidMode.value
        _android = AndroidClient.init(name: "Android Device", state: ClientState.init(booleanLiteral: androidEnable))
        
        let iOSSimEnable = !qrEnable && !androidEnable
        _iOSSim = iOSSimulatorClient.init(name: "iOS Simulator", state: ClientState.init(booleanLiteral: iOSSimEnable))
        
        //setup default
        _clients = [_qr, _iOSSim, _android]
    }
    
    func fire(scheme: SchemeItem) {
        Answers.logCustomEvent(withName: "Fire", customAttributes: ["Mode": ConfigCenter.sharedInstance.mode])

        _clients.fire(scheme: scheme)
    }
    
    func radioOniOS() {
        _clients = _clients.radioOn(client: _iOSSim)
    }
    
    func radioOnAndroid() {
        _clients = _clients.radioOn(client: _android)
    }
    
    func radioOnQRCode() {
        _clients = _clients.radioOn(client: _qr)
    }
    
    //MARK: -
    //MARK: iOS Device
    
    func updateiOSDeviceName(with bonjourClient: BonjourClient) {
        _clients = _clients.map {
            guard let iOSClient = $0 as? iOSDeviceClient else {
                return $0
            }
            
            guard iOSClient.bonjourClient == bonjourClient else {
                return $0
            }
            
            var ret = iOSClient
            ret.name = bonjourClient.name
            print("Connected to \(bonjourClient.name)")
            
            return ret
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: kRebuildDeviceMenuNotification), object: nil)
    }
    
    func addiOSDevice(client: iOSDeviceClient) {
        _clients.append(client)
        
        //turn off any devices except all iOSDeviceClient
        _clients = _clients.map {
            guard $0 is iOSDeviceClient else {
                var ret = $0
                ret.state = ClientState.init(booleanLiteral: false)
                return ret
            }
            return $0
        }
    }
    
    func removeiOSDevice(_ bonjourClient: BonjourClient) {
        _clients = _clients.filter {
            guard let i = $0 as? iOSDeviceClient else {
                return true
            }
            return i.bonjourClient != bonjourClient
        }
        
        if iOSClients.count == 1 {
            turnOn1Client()
        }
        
        print("Disconnected to \(bonjourClient.name)")
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: kRebuildDeviceMenuNotification), object: nil)
    }
    
    func removeAlliOSDevices() {
        _clients = _clients.filter {
            guard $0 is iOSDeviceClient else {
                return true
            }
            return false
        }
        turnOn1Client()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: kRebuildDeviceMenuNotification), object: nil)
    }
    
    //Turn on 1 client when remove all iOS devices
    private func turnOn1Client() {
        let config = ConfigCenter.sharedInstance
        if config.needQRCode.value {
            radioOnQRCode()
        } else if config.androidMode.value {
            radioOnAndroid()
        } else {
            _clients = _clients.radioOn(client: _iOSSim)
        }
    }
}

extension Array where Iterator.Element == Client {
    
    func radioOn(client: Client) -> [Client] {
        return map {
            var temp = $0
            if temp.name == client.name {
                temp.state = ClientState(booleanLiteral: true)
            } else {
                temp.state = ClientState(booleanLiteral: false)
            }
            return temp
        }
    }
    
    func fire(scheme: SchemeItem) {
        forEach { client in
            if client.state == .on {
                client.consume(scheme: scheme)
            }
        }
    }
}
