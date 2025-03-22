//
//  SceneDelegate.swift
//  AppStore
//
//  Created by Navdeep    on 23/10/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            guard let windowScene = (scene as? UIWindowScene) else { return }
            
            let window = UIWindow(windowScene: windowScene)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            
            if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
              
                window.rootViewController = storyboard.instantiateViewController(withIdentifier: "TabBarController")
            } else {
                
                window.rootViewController = storyboard.instantiateViewController(withIdentifier: "onbordingViewController")
            }
            
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        
        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
       
    }




