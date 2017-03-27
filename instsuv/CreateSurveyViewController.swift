//
//  CreateSurveyViewController.swift
//  instsuv
//
//  Created by 申潤五 on 2016/12/24.
//  Copyright © 2016年 申潤五. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation


class CreateSurveyViewController: UIViewController, UIPickerViewDelegate ,UIPickerViewDataSource {

    @IBOutlet weak var topic: UITextField!
    @IBOutlet weak var option1: UITextField!
    @IBOutlet weak var option2: UITextField!
    @IBOutlet weak var option3: UITextField!
    @IBOutlet weak var option4: UITextField!
    @IBOutlet weak var option5: UITextField!
    
    @IBOutlet weak var option3title: UILabel!
    @IBOutlet weak var option4title: UILabel!
    @IBOutlet weak var option5title: UILabel!

    @IBOutlet weak var anonSwich: UISwitch!
    @IBOutlet weak var suggestSwitch: UISwitch!
    
    
    @IBOutlet weak var anonLabel: UILabel!
    @IBOutlet weak var suggestLabel: UILabel!
    
    @IBOutlet weak var selection: UIPickerView!
    @IBOutlet weak var optionNumber: UILabel!
    @IBOutlet weak var surveyPeriod: UILabel!
    
    var locationManager:CLLocationManager? = CLLocationManager()
    
    
    let selections = ["選項數量","有效時間"]
    let numberStringForOption = ["二個","三個","四個","五個"]
    let periodForSurvey = ["一小時","四小時","24小時","一星期"]
    var numberForOptionsID = 0
    var periodForSurveyID = 0
    
    
    // PickerView:
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return numberStringForOption.count
        }
        return periodForSurvey.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return numberStringForOption[row]
        }
        return periodForSurvey[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch component {
        case 0:
            optionNumber.text = "選項:\(numberStringForOption[row])"
            setNumberOfOptionView(numberOfOption: row+2)
            numberForOptionsID = row
        default:
            surveyPeriod.text = "有效期：\(periodForSurvey[row])"
            periodForSurveyID = row
        }
        
    }
    
    
    
    // main:
    override func viewDidLoad() {
        super.viewDidLoad()
        selection.dataSource = self
        selection.delegate = self
        setNumberOfOptionView(numberOfOption: 2)
        locationManager?.requestWhenInUseAuthorization()

    }
    
    
    @IBAction func submit(_ sender: UIButton) {
        let comformAlert = UIAlertController()
        comformAlert.title = "確認問卷內容"
        
        
        
        //檢查正確性, 不得空白
        if let theTopic = self.topic?.text,
            let theOption1 = self.option1?.text,
            let theOption2 = self.option2?.text,
            let theOption3 = self.option3?.text,
            let theOption4 = self.option4?.text,
            let theOption5 = self.option5?.text{
            
            if theTopic == ""{
                self.showAlert(message: "主題不得空白")
                return
            }
            
            if theOption1 == "" || theOption2 == ""{
                self.showAlert(message: "選項不得空白")
                return
            }
            
            if numberForOptionsID == 1 && theOption3 == "" {
                self.showAlert(message: "選項不得空白")
                return
            }
            
            if numberForOptionsID == 2 && theOption3 == "" && theOption4 == "" {
                self.showAlert(message: "選項不得空白")
                return
            }
            
            if numberForOptionsID == 3 && theOption3 == "" && theOption4 == "" && theOption5 == "" {
                self.showAlert(message: "選項不得空白")
                return
            }
            
            
        }

        var messageString = "有效期：\(periodForSurvey[periodForSurveyID])\n選項數：\(numberStringForOption[numberForOptionsID]) \n主題：\(topic.text!)\n選項1:\(option1.text!)\n選項2:\(option2.text!)"
    
        
        switch (numberForOptionsID) {
        case 1:
            messageString = "\(messageString)\n選項3:\(option3.text!)"
        case 2:
            messageString = "\(messageString)\n選項3:\(option3.text!)\n選項4:\(option4.text!)"
        case 3:
            messageString = "\(messageString)\n選項3:\(option3.text!)\n選項4:\(option4.text!)\n選項5:\(option5.text!)"
        default: break
        }
        comformAlert.message = messageString
        
        
        //按下確定後的處理
        let comformButton = UIAlertAction(title: "確定", style: UIAlertActionStyle.default) { (action) in
            
            // 產生 showID
            var showID = Int( arc4random() % 89999 ) + 10001
            if self.userDisplayName() == "Survey    Adm" {
                showID = 10000
            }
            
            // 寫入主 Tree (使用自定的 UUID)
            let surveyUUID = NSUUID().uuidString
            
            
            var ref = FIRDatabase.database().reference().child("survey/\(surveyUUID)")
            
            // 匿名，建議與選項數量
            ref.child("allowAnonymity").setValue("\(self.anonSwich.isOn)")
            ref.child("suggest").setValue("\(self.suggestSwitch.isOn)")
            ref.child("numberOfOption").setValue("\(self.numberForOptionsID+2)")
            
            //主題與選項
            ref.child("creatorDisplayname").setValue(self.userDisplayName())
            ref.child("creatorUid").setValue(self.userUid())
            ref.child("topic").setValue(self.topic.text)
            ref.child("option1").setValue(self.option1.text)
            ref.child("option2").setValue(self.option2.text)
            
            switch self.numberForOptionsID {
            case 1:
                ref.child("option3").setValue(self.option3.text)
            case 2:
                ref.child("option3").setValue(self.option3.text)
                ref.child("option4").setValue(self.option4.text)
            case 3:
                ref.child("option3").setValue(self.option3.text)
                ref.child("option4").setValue(self.option4.text)
                ref.child("option5").setValue(self.option5.text)
            default: break
            }
            
            // 開始結束時間與顯示代碼
            
            
            var endOfSurveyTimeNumber:Int64 = 0
            switch self.periodForSurveyID {
            case 3:
                endOfSurveyTimeNumber = self.getDateInt(date: Date())+(7*24*60*60*1000)
            case 2:
                endOfSurveyTimeNumber = self.getDateInt(date: Date())+(24*60*60*1000)
            case 1:
                endOfSurveyTimeNumber = self.getDateInt(date: Date())+(4*60*60*1000)
            case 0:
                endOfSurveyTimeNumber = self.getDateInt(date: Date())+(60*60*1000)
            default:break
            }
            
            ref.child("endOfSurveyTime").setValue("\(endOfSurveyTimeNumber)")
            ref.child("createTime").setValue("\(self.getDateInt(date: Date()))")
            ref.child("showID").setValue(String(showID))
            
            
            
            
            //寫入尋清單(idlist)
            ref = FIRDatabase.database().reference().child("survey/idlist/\(String(showID))/\(surveyUUID)")
            
            ref.child("creatorDisplayname").setValue(self.userDisplayName())
            ref.child("topic").setValue(self.topic.text)
            ref.child("endOfSurveyTime").setValue("\(endOfSurveyTimeNumber)")
            
            //寫入個人資料
            ref = FIRDatabase.database().reference().child("user/\(self.userUid())/mySurvey/\(surveyUUID)")
            
            ref.child("endOfSurveyTime").setValue("\(endOfSurveyTimeNumber)")
            ref.child("showID").setValue(String(showID))
            ref.child("topic").setValue(self.topic.text)
            

            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = "M/dd HH:mm"
            
            //寫入區域清單
            ref = FIRDatabase.database().reference().child("survey/locationList/\(surveyUUID)")
            ref.child("creatorDisplayname").setValue(self.userDisplayName())
            ref.child("topic").setValue(self.topic.text)
            ref.child("endOfSurveyTime").setValue("\(endOfSurveyTimeNumber)")
            
            let currentLocation = self.locationManager?.location?.coordinate
            ref.child("la").setValue(currentLocation?.latitude)
            ref.child("ro").setValue(currentLocation?.longitude)
            

            
            //清除表單
            self.resetForm()
            self.showAlert(message: "己完成建立，代碼:\(showID), 或按下【我建立的調查】進行查詢，有效期限至：\(formatter.string(from: self.nToDate(datenumber: endOfSurveyTimeNumber)))")
            
            
            
            self.tabBarController?.selectedIndex = 0
        }
        comformAlert.addAction(comformButton)
        let cancleButton = UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler: nil)
        comformAlert.addAction(cancleButton)
        self.present(comformAlert, animated: true, completion: nil)
    }
    
    // 設定選項數量
    
    func setNumberOfOptionView( numberOfOption:Int){
        switch numberOfOption {
        case 2:
            setZeroHForView(theView: option3,height: 0)
            setZeroHForView(theView: option4,height: 0)
            setZeroHForView(theView: option5,height: 0)
            option3title.isHidden = true
            option4title.isHidden = true
            option5title.isHidden = true
        case 3:
            setZeroHForView(theView: option3,height: 30)
            setZeroHForView(theView: option4,height: 0)
            setZeroHForView(theView: option5,height: 0)
            option3title.isHidden = false
            option4title.isHidden = true
            option5title.isHidden = true
        case 4:
            setZeroHForView(theView: option3,height: 30)
            setZeroHForView(theView: option4,height: 30)
            setZeroHForView(theView: option5,height: 0)
            option3title.isHidden = false
            option4title.isHidden = false
            option5title.isHidden = true
        case 5:
            setZeroHForView(theView: option3,height: 30)
            setZeroHForView(theView: option4,height: 30)
            setZeroHForView(theView: option5,height: 30)
            option3title.isHidden = false
            option4title.isHidden = false
            option5title.isHidden = false
        default:break
        }
        
        
        
    }
    
    func resetForm(){
        topic.text = ""
        option1.text  = ""
        option2.text  = ""
        option3.text  = ""
        option4.text  = ""
        option5.text  = ""
        anonSwich.isOn = true
        suggestSwitch.isOn = true
        selection.selectRow(0, inComponent: 0, animated: false)
        selection.selectRow(1, inComponent: 0, animated: false)
        self.pickerView(selection, didSelectRow: 0, inComponent: 0)
        self.pickerView(selection, didSelectRow: 0, inComponent: 1)
        selection.selectRow(0, inComponent: 0, animated: false)
        selection.selectRow(0, inComponent: 1, animated: false)
        
    }
    


    
}
