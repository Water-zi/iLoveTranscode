//
//  iLoveTranscodeApp.swift
//  iLoveTranscode
//
//  Created by 唐梓皓 on 2024/1/30.
//

import SwiftUI

@main
struct iLoveTranscodeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear(perform: {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                        if success {
                            print("All set!")
                        } else if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                })
        }
    }
}
