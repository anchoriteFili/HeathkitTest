//
//  AppDelegate.swift
//  HealthKitTest
//
//  Created by zetafin on 2019/1/9.
//  Copyright © 2019 赵宏亚. All rights reserved.
//

import UIKit
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        healthKit { (succ) in
            if succ {
                //读取步数(读取当前手机中的步数)
                self.readDataFromService()
                //存储步数（存储步数到手机）
                //                self.saveDataToDevice()
            }
        }
        return true
    }
    
    //设备是否支持 允许获取步数
    var healthStore: HKHealthStore?
    func healthKit(succ: @escaping (Bool) -> Void) {
        if (!HKHealthStore.isHealthDataAvailable()) {
            print("不支持")
            return
        } else {
            healthStore = HKHealthStore();
            let readDataTypes = dataTypeStep()
            healthStore?.requestAuthorization(toShare: dataTypeStep(), read: readDataTypes, completion: { (success, error) in
                succ(success)
            })
        }
    }
    
    //获取类型 （步数）
    func dataTypeStep() -> Set<HKQuantityType> {
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount);
        var set = Set<HKQuantityType>()
        set.insert(stepCountType!)
        return set
    }
    
    //读取步数
    func readDataFromService() {
        let calendar = NSCalendar.current
        let now = Date();
        var components = calendar.dateComponents(Set(arrayLiteral: .year, .month, .day, .hour, .minute, .second), from: now)
        let hour: Int = components.hour!;
        let minute: Int = components.minute!;
        let second: Int = components.second!;
        
        //读取某个时间段内的步数
        let s = Date(timeIntervalSinceNow: -(Double(hour * 3600 + minute * 60 + second)))
        let e = Date(timeIntervalSinceNow: -(Double(hour * 3600 + minute * 60 + second)) + 86400)
        
        guard let step = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: s, end: e)
        let query = HKSampleQuery(sampleType: step, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [timeSortDescriptor]) { (query, results, error) in
            
            guard let results = results as? [HKQuantitySample] else { return }
            var step = 0
            for quantitySample in results {
                let quantity = quantitySample.quantity
                let heightUnit = HKUnit.count()
                let usersHeight = quantity.doubleValue(for: heightUnit)
                step += Int(usersHeight)
            }
            
            print("***** \(step)")
        }
        healthStore?.execute(query)
    }
    
    //写入步数
    func saveDataToDevice() {
        //设置时间段， 将步数存储到设置的时间范围内
        let tmp = Date();
        let end = Date(timeInterval: -3000, since: tmp)
        let start = Date(timeInterval: -5000, since: tmp)
        
        let step = HKObjectType.quantityType(forIdentifier: .stepCount)
        let quant = HKQuantity(unit: HKUnit.count(), doubleValue: Double(1000))
        //device信息可以自定义，这里模仿 Apple Watch
        //原本写这个demo的用途是方便完成 某个app的步数规定， 但写完后最终发现， 并无用途，
        //该app是通过bundleIdentifier 来区分步数来源，只能获取 iphone  或 appleWatch 的步数
        //也就是职能获取bundleIdentifier = com.apple.***的步数
        let device = HKDevice.init(name: "Apple Watch", manufacturer: "Apple", model: "Watch", hardwareVersion: "Watch2,3", firmwareVersion: nil, softwareVersion: "3.2.2", localIdentifier: nil, udiDeviceIdentifier: nil)
        let obj = HKQuantitySample.init(type: step!, quantity: quant, start: start, end: end, device: device, metadata: nil)
        healthStore?.save(obj, withCompletion: { (success, error) in
            //存储完成回调
        })
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
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

