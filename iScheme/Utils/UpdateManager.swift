//
//  UpdateManager.swift
//  iScheme
//
//  Created by lingwan on 16/7/2.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Foundation
import Sparkle

struct UpdateManager {
    func checkUpdate() {
        let updater = SUUpdater.shared()
        updater?.feedURL = URL(string: "http://schememanager-store.oss-cn-shanghai.aliyuncs.com/appcast.xml")
        updater?.automaticallyDownloadsUpdates = false
        updater?.checkForUpdatesInBackground()
    }
}
