//
//  PersonalDataViewController.swift
//  instsuv
//
//  Created by 申潤五 on 2016/12/11.
//  Copyright © 2016年 申潤五. All rights reserved.
//

import UIKit
import Firebase

class PersonalDataViewController: UIViewController {

    @IBOutlet weak var displayNameInput: UITextField!
    @IBOutlet weak var announcementWeb: UIWebView!
    @IBOutlet weak var account: UILabel!
    @IBOutlet weak var mailVerificationButton: UIButton!
    
    @IBOutlet weak var mailVerificationStatus: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showWaiting()
        
        
        //顯示公佈欄
        
        let url = NSURL(string:  "https://dannytest001-21971.firebaseapp.com/001/")
        let urlRequest = NSURLRequest(url: url! as URL)
        announcementWeb.loadRequest(urlRequest as URLRequest)
        
        
        
        //顯示使用者資料
            //帳號與顯示名稱
        let userRef = FIRDatabase.database().reference().child("user").child((FIRAuth.auth()?.currentUser?.uid)!)
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            self.displayNameInput.text=value?.object(forKey: "displayname") as? String
            self.account.text=value?.object(forKey: "email") as? String
            self.stopWaiting()
            // ...
        }) { (error) in
            print(error.localizedDescription)
            self.showAlert(message: "錯誤：\n\(error.localizedDescription)")
        }

        
        //是否完成電子郵件驗證
        
        
        
        
        if let isEmailVerified=FIRAuth.auth()?.currentUser?.isEmailVerified{
            if isEmailVerified{
                mailVerificationStatus.text = "己完成電子郵件驗證"
                self.mailVerificationButton.isHidden = true
            }else{
                mailVerificationStatus.text = "尚未完成電子郵件驗證"
                self.mailVerificationButton.isHidden = false
            }
        }
        
        
        
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func changeDisplayName(_ sender: UIButton) {
        
        
    }
    
    
    @IBAction func logout(_ sender: UIButton) {
        
        try! FIRAuth.auth()!.signOut()
        print("logout")
        
        self.navigationController?.popViewController(animated: true)

    
    }
    
    @IBAction func requestForMailVerification(_ sender: UIButton) {
        FIRAuth.auth()?.currentUser?.sendEmailVerification(completion: { (error) in
            if let errMsg = error?.localizedDescription{
                self.showAlert(message: "發生錯誤：\n\(errMsg)")
            }else{
                self.showAlert(message: "查看郵件")
            }
            
        })
        
    }


}
