//
//  iLoveTranscodeApp.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/1/30.
//

import SwiftUI

@main
struct iLoveTranscodeApp: App {
    
    @UIApplicationDelegateAdaptor var appDelegate: iLoveTranscodeAppDelegate
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
