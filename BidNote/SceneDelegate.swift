//
//  SceneDelegate.swift
//  BidNote
//
//  Created by Gavin Wolfe on 2/5/23.
//

import UIKit
import Firebase
import OneSignalFramework
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UIApplicationDelegate {

    var window: UIWindow?

    

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        UIApplication.shared.delegate = self
        guard let _ = (scene as? UIWindowScene) else { return }
        
        
        let apparence = UITabBarAppearance()
        //apparence.backgroundColor = .opaqueSeparator
        if #available(iOS 15.0, *) {UITabBar.appearance().scrollEdgeAppearance = apparence}
        if #available(iOS 15, *) {
//            let appearance = UINavigationBarAppearance()
//            UINavigationBar.appearance().standardAppearance = appearance
//            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        let rootVC = self.window?.rootViewController as! MainSceneTabBarController
        guard let notifiResponse = connectionOptions.notificationResponse else { return }
            if notifiResponse.notification.request.trigger is UNPushNotificationTrigger{ //Remote Notification
                rootVC.selectedIndex = 1
            }
    }
    

    
//    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
//        URLContexts.forEach { context in
//            if context.url.scheme?.localizedCaseInsensitiveCompare("berlarkSoftware.BidNote.payments") == .orderedSame {
//                _ = BTAppContextSwitcher.sharedInstance.handleOpenURL(context: context)
//            }
//        }
//    }
    

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        
        let ref = Database.database().reference()
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { (settings) in
            if(settings.authorizationStatus == .authorized) {
                print("called did reg")
                if let id = OneSignal.User.pushSubscription.id {
                    if let uid = Auth.auth().currentUser?.uid {
                        ref.child("users").child(uid).updateChildValues(["userKey": id])
                        print("did register updated")
                    }
                }
            } else {
                if let uid = Auth.auth().currentUser?.uid {
                    ref.child("users").child(uid).child("userKey").removeValue()
                }
            }
        }
        let rootVC = self.window?.rootViewController as! MainSceneTabBarController
        if let uid = Auth.auth().currentUser?.uid {
            ref.child("users").child(uid).child("inboxUnseen").observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                   rootVC.tabBar.items?[1].badgeValue = "1"
                } else {
                   rootVC.tabBar.items?[1].badgeValue = nil
                }
            })
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

