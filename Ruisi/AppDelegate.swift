//
//  AppDelegate.swift
//  Ruisi
//
//  Created by yang on 2017/4/17.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import CoreData
import CoreSpotlight

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // init theme
        ThemeManager.initTheme()

        Reachability.startCheckHost(host: App.HOST_RS)
        
        SQLiteDatabase.initDatabase()
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + 1) {
            let his = SQLiteDatabase.instance?.loadReadHistory(count: 800, offset: 800)
            
            // init spotlight
            SpotlightManager.sharedInstance.initSpotlight(his: his)
            
            SQLiteDatabase.clearOldData(size: 800)
        }
        return true
    }
    
    // 从ShortCut打开
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
        case "ShortCutLove":
            UIApplication.shared.open(URL(string: "itms-apps://itunes.apple.com/app/\(App.APP_ID)")!)
        default:
            break
        }
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        SQLiteDatabase.close()
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }

}

//MARK: - Spotlight Search
extension AppDelegate {
    
    // 从Spotlight打开
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Called when Spotlight item tapped. Do anything with specified data.
        
        if userActivity.activityType == CSSearchableItemActionType {
            if let userInfo = userActivity.userInfo {
                let selectedItem = userInfo[CSSearchableItemActivityIdentifier] as! String
                
                
                // Read data from selected activity info that was set to related item, and save into dictionary.
                var valueDict = Dictionary<String,String>()
                
                if let components = URLComponents(string: selectedItem), let queryItems = components.queryItems {
                    for item in queryItems {
                        valueDict[item.name] = item.value
                    }
                }
                
                print("Selected Item Parameters: \(valueDict)")
                if let vc = UIApplication.shared.keyWindow?.rootViewController, let dest = vc.storyboard?.instantiateViewController(withIdentifier: "PostViewController") as? PostViewController {
                    
                    dest.tid = Int(valueDict["tid"]!)
                    let navVc = UINavigationController(rootViewController: dest)
                    dest.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: dest, action: #selector(dest.dismissFormSpotlight))
                    
                    vc.present(navVc, animated: true, completion: nil)
                }
            
                
            }
        }
        
        return true
    }
}

