
//  ViewController.swift
//  instsuv
//
//  Created by 申潤五 on 2016/10/10.
//  Copyright © 2016年 申潤五. All rights reserved.
//

import UIKit
import Firebase


extension UIViewController{
    
    
    //將 View 中 constraint ID 為 height 者，設為零
    func setZeroHForView(theView: UIView, height:CGFloat){
        for constraint in theView.constraints{
            if constraint.identifier == "height"{
                constraint.constant = height
            }
        }
    }
    
    
    //取得使用者名稱 （由UserDefuault）
    func userDisplayName() -> String{
        return UserDefaults.standard.object(forKey: "displayName") as! String
    }
    
    //取得使用者Uid （由UserDefuault）
    func userUid() -> String{
        return UserDefaults.standard.object(forKey: "uid") as! String
    }
    
    //顯示等待服務（轉圈圈）
    func showWaiting(){
        let caverView = UIView()
        caverView.frame = self.view.frame
        caverView.backgroundColor = UIColor.white
        caverView.alpha = 0.5
        caverView.tag = 10001
        
        let waitingView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        waitingView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        waitingView.center = self.view.center
        waitingView.startAnimating()
        caverView.addSubview(waitingView)
        self.view.addSubview(caverView)
    }
    
    //取消等待服務（取消轉圈圈）
    func stopWaiting(){
        for  view in self.view.subviews{
            if (view.tag == 10001){
                view.removeFromSuperview()
            }
        }
    
    }
    
    //顯示訊息
    func showAlert(message:String)  {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "我知道了", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true,completion: nil)
    }
    
    //檢查是否為 email 格式
    func checkIfEmailFormat(mail:String) -> Bool {
        var returnValue = false
        let mailPattern = "^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$"
        let mailRegular = try! NSRegularExpression(pattern: mailPattern, options: .caseInsensitive)
        let results = mailRegular.matches(in: mail, options: [], range:  NSMakeRange(0, (mail as NSString).length))
        if results.count > 0 {
            returnValue = true
        }
        return returnValue
    }
    
    //取得與 Java 相同的 Date 數字
    func getDateInt( date : Date ) -> Int64{
        return Int64((date.timeIntervalSince1970) * 1000)
    }
    
    //轉成 Java DateLong 轉成 NSDate
    func nToDate( datenumber : Int64 ) -> Date {
        let tis = Double(datenumber) / 1000.0
        return Date.init(timeIntervalSince1970: tis)
    }
    
}


//登入頁面
class LoginViewController: UIViewController {

    @IBOutlet weak var account: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var newAccountButton: UIButton!
    
    let waitingForNetworkCover = UIActivityIndicatorView()
    let userDefault = UserDefaults.standard
    var logined=false
    

//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?){
//    
//    }
    
    var ref:FIRDatabaseReference!//=FIRDatabase.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        account.text = userDefault.string(forKey: "lastLoginUserAccount")
        
        FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            
            
            if let user = user {
                if let email = user.email{
                    print(email)
                }
            }
            
            
        })
        
        
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            
       
            if let user=user{
            
                if(!self.logined){
                    self.userDefault.set(user.email, forKey: "email")
                    self.userDefault.set(user.uid, forKey:  "uid")
                    self.userDefault.synchronize()
                    let ref = FIRDatabase.database().reference().child("user").child((user.uid))
                    ref.observeSingleEvent(of: .value , with: { (snapshot) in
                        let value = snapshot.value as? NSDictionary
                        self.userDefault.set(value?.object(forKey: "displayname") as? String, forKey:"displayName")
                        self.userDefault.synchronize()
                    })
                    
                self.password.text = ""
                self.performSegue(withIdentifier: "gotoStart", sender: "Start")
                self.logined=true
                }
            } else {
                // User is singed out
                self.logined=false
                self.stopWaiting()

            }
        
        }

    }
    


    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier{
            if identifier == "createAccount"{
                let nextVC = segue.destination as! SingInViewController
                nextVC.loginVC=self

//              準備傳值 let controller = segue.destination as! UITableViewController

            }
        }
    }

    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    
    //登入按鍵
    @IBAction func login(_ sender: AnyObject) {


        if let theAccount=self.account?.text,
           let thePassword=self.password?.text
        {
                if (theAccount==""){
                    showAlert(message: "帳號不能空白")
                    return
                }
            
                if (!checkIfEmailFormat(mail: theAccount)){
                    showAlert(message: "帳號必需為 E-mail 格式 如 myaccount@domain.com")
                    return
                }
                if (thePassword==""){
                    showAlert(message: "密碼不能空白")
                    return
                }
            self.showWaiting()

            
            
                FIRAuth.auth()?.signIn(withEmail: "a@b.c", password: "xxx", completion: { (user, error) in
                    if( user != nil ){
                        print("登入成功")
                    }else{
                        print("登入失敗\(error?.localizedDescription)")
                    }
                })
            

                FIRAuth.auth()?.signIn(withEmail: theAccount, password: thePassword){(user,error) in
                    if( user != nil ){
                        self.showAlert(message: "登人驗證成功")
                    }else{
                        self.stopWaiting()
                        let message = "無法登入，錯誤訊息為：\n\((error?.localizedDescription)!)"
                        self.showAlert(message: message)
                    }
            }
        }
        }

    

    
    
}



// 建立新帳號
class SingInViewController: UIViewController {

    @IBOutlet weak var displayName: UITextField!
    @IBOutlet weak var account: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var rePassword: UITextField!
    var loginVC:LoginViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
    }
    
    
    //try 建立新帳號
    @IBAction func createNewAccount(_ sender: UIButton) {
        
        if let theDisplayName=self.displayName?.text,
            let theAccount=self.account?.text,
            let thePassword=self.password?.text,
            let theRePassword=self.rePassword?.text
            {
                //檢查欄位格式
                if (theDisplayName=="") {
                    showAlert(message: "暱稱不得空白")
                    return
                }
                if (theAccount=="") {
                    showAlert(message: "帳號不得空白")
                    return
                }
                if (!checkIfEmailFormat(mail: theAccount)){
                    showAlert(message: "帳號必需為 E-mail 格式 如 myaccount@domain.com")
                }
                if ( thePassword.lengthOfBytes(using: String.Encoding.utf8)<6 ){
                    showAlert(message: "輸入密碼最小不得少於六個字元，請重新修正與確認")
                    return
                }
                if (thePassword != theRePassword){
                    showAlert(message: "輸入的兩次密碼必需相同，請重新修正與確認")
                    return
                }
                
                
                _ = self.navigationController?.popViewController(animated: true)
                self.loginVC?.showWaiting()
                
                //實作建立帳號
                showWaiting()
                FIRAuth.auth()?.createUser(withEmail: theAccount, password: thePassword) { (user, error) in
                    if( user != nil ){
                        
                        self.stopWaiting()
                        self.showAlert(message: "己完成帳號建立")
                        let ref = FIRDatabase.database().reference().child("user").child((user?.uid)!)
                        ref.child("Uid").setValue((user?.uid)!)
                        ref.child("displayname").setValue(theDisplayName)
                        ref.child("email").setValue(theAccount)
                        
                        
                    }else{
                        self.showAlert(message: "無法建立帳號，原因說明如下：\n\((error?.localizedDescription)!)")
                        self.stopWaiting()
                        self.loginVC?.stopWaiting()
                    }
                    // ...
                }
                
                
                
                
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    

    
}

class ForgetPasswrodViewController: UIViewController {
    
    @IBOutlet weak var account: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
    }
    
    @IBAction func sendForgetPasswrod(_ sender: UIButton) {
        
       
        
        if let theAccount=self.account?.text{
            //檢查電子郵件欄是否為空白
            if (theAccount==""){
                showAlert(message:"電子郵件欄不得空白")
                return
            }
            showWaiting()
            FIRAuth.auth()?.sendPasswordReset(withEmail: theAccount){ error in
                if  (error != nil) {
                    self.showAlert(message: "發生錯誤，訊息為:\n\((error?.localizedDescription)!)")
                    self.stopWaiting()
                    // An error happened.
                } else {
                    
                    self.stopWaiting()
                    let message = "請至你的電子郵件查看！"
                    let alert = UIAlertController(title: "提示", message: message, preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "我知道了", style: UIAlertActionStyle.default, handler: { (action) in
                        super.navigationController?.popViewController(animated: true)
                    })
                    alert.addAction(okAction)
                    self.present(alert, animated: true,completion:nil)
                    

                }
            }
            
        
        }
    }
    
    
    
}
