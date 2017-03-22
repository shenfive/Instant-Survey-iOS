//
//  FillSurveyViewController.swift
//  instsuv
//
//  Created by 申潤五 on 2016/12/17.
//  Copyright © 2016年 申潤五. All rights reserved.
//

import UIKit
import Firebase

class FillSurveyViewController: UIViewController {

    @IBOutlet weak var surveyDisplayName: UILabel!
    @IBOutlet weak var topic: UILabel!
    @IBOutlet weak var option1: UIButton!
    @IBOutlet weak var option2: UIButton!
    @IBOutlet weak var option3: UIButton!
    @IBOutlet weak var option4: UIButton!
    @IBOutlet weak var option5: UIButton!
    @IBOutlet weak var submit: UIButton!
  
    @IBOutlet weak var surveyEndTime: UILabel!
    @IBOutlet weak var surveyAnswerName: UITextField!
    @IBOutlet weak var suggestion: UITextField!
    @IBOutlet weak var suggestionTtitle: UILabel!
    @IBOutlet weak var selected: UILabel!
    @IBOutlet weak var surveyAnswoerNameSwitch: UISegmentedControl!
    @IBOutlet weak var surveyShowID: UILabel!
    
    
    
    var endOfSurveyTime:String = ""

    var selectedID:String = "0"
    
    var surveyID:String = ""
    
    var alloAnonymity = true
    
    var numberOfOption = 2
    

    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showWaiting()
        
        surveyAnswerName.text = self.userDisplayName()
        
        let dbref = FIRDatabase.database().reference().child("survey/\(surveyID)")
        dbref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            var isAnswered = false //假設尚未回覆過調查
            if let surveyContent = snapshot.value as? NSDictionary{
                self.surveyDisplayName.text = (surveyContent.object(forKey: "creatorDisplayname") as! String)
                self.topic.text = (surveyContent.object(forKey: "topic") as! String)
            
                self.endOfSurveyTime = surveyContent.object(forKey: "endOfSurveyTime") as! String
                
                self.surveyShowID.text = surveyContent.object(forKey: "showID") as! String
                
                
                
                
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.dateFormat = "M/dd HH:mm"
                self.surveyEndTime.text = formatter.string(from: self.nToDate(datenumber: Int64(self.endOfSurveyTime)!))
                self.option1.setTitle(surveyContent.object(forKey: "option1") as? String, for: .normal)
                self.option2.setTitle(surveyContent.object(forKey: "option2") as? String, for: .normal)
                
                if (surveyContent.object(forKey: "allowAnonymity") as! String) != "true" {
                    self.alloAnonymity = false
                }
                if (surveyContent.object(forKey: "suggest") as! String) != "true" {
                    self.setZeroHForView(theView: self.suggestion, height: 0)
                    self.suggestionTtitle.isHidden = true
                }
                
                
                let numberOfOption = Int((surveyContent.object(forKey:"numberOfOption") as? String)!)!
                self.numberOfOption = numberOfOption
                
                switch numberOfOption {
                case 2:
                    self.option3.isHidden = true
                    self.setZeroHForView(theView: self.option3, height: 0)
                    
                    self.option4.isHidden = true
                    self.setZeroHForView(theView: self.option4, height: 0)

                    self.option5.isHidden = true
                    self.setZeroHForView(theView: self.option4, height: 0)


                    
                case 3:
                    
                    self.option3.setTitle(surveyContent.object(forKey: "option3") as? String, for: .normal)
                    
                    self.option4.isHidden = true
                    self.setZeroHForView(theView: self.option4, height: 0)

                    
                    self.option5.isHidden = true
                    self.setZeroHForView(theView: self.option5, height: 0)

                case 4:
                    self.option3.setTitle(surveyContent.object(forKey: "option3") as? String, for: .normal)
                    self.option4.setTitle(surveyContent.object(forKey: "option4") as? String, for: .normal)
                    self.option5.isHidden = true
                    self.setZeroHForView(theView: self.option5, height: 0)

                case 5:
                    self.option3.setTitle(surveyContent.object(forKey: "option3") as? String, for: .normal)
                    self.option4.setTitle(surveyContent.object(forKey: "option4") as? String, for: .normal)
                    self.option5.setTitle(surveyContent.object(forKey: "option5") as? String, for: .normal)
                    
                default:break
                }
                
                //處理匿名問題
                self.surveyAnswoerNameSwitch.isEnabled = self.alloAnonymity
                
                
                
                // 處理過期與己回應的情況

                
                //處理己經回應的情況
                
                if let answers = surveyContent.object(forKey: "answers") as! NSDictionary?{
                    if let theSelected = answers.object(forKey: self.userUid()) as! NSDictionary?{
                        self.selectedID = theSelected.object(forKey: "selectedID") as! String
                        switch self.selectedID {
                        case "5":
                            self.selected.text  = self.option5.currentTitle
                        case "4":
                            self.selected.text  = self.option4.currentTitle
                        case "3":
                            self.selected.text  = self.option3.currentTitle
                        case "2":
                            self.selected.text  = self.option2.currentTitle
                        default:
                            self.selected.text  = self.option1.currentTitle
                        }
                        self.suggestion.text = theSelected.object(forKey: "suggest") as? String
                        isAnswered = true
                    }
                }
                
                //看調查是否結束若己經結束，就設定無法回應, 並依狀況告知使用者
                if self.getDateInt(date: Date()) > Int64(self.endOfSurveyTime)!{
                    self.submit.isHidden = true
                    self.surveyAnswoerNameSwitch.isEnabled = false
                    self.option1.isEnabled = false
                    self.option2.isEnabled = false
                    self.option3.isEnabled = false
                    self.option4.isEnabled = false
                    self.option5.isEnabled = false
                    self.suggestion.isEnabled = false
                    if isAnswered{
                       self.showAlert(message: "您曾經回覆，上次您回覆為 [\(self.selected.text!)]，但本調查己經過期，可以直接看結果")
                    }else{
                        self.showAlert(message: "本調查己經過期，可以直接看結果")
                    }
                }else{
                    if isAnswered{
                        self.showAlert(message: "您曾經回覆，上次您回覆為 [\(self.selected.text!)]，可以修正或直接看結果")
                    }
                }
                
            
                
                
                
                self.stopWaiting()
            }
        })
        {(error) in
        }
        
        
        
    
    }
    
    
    
    //按下選項時的處理
    
    @IBAction func touchOptions(_ sender: UIButton) {
        self.selectedID = String(sender.tag)
        self.selected.text = sender.titleLabel?.text
    }
    
    
    
    //取消

    @IBAction func cancle(_ sender: UIButton) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    //確定
    
    @IBAction func submit(_ sender: UIButton) {
        
        
        if( selectedID == "0" ){
            self.showAlert(message: "尚未選擇，請做出選項!")
            return
        }
        
        
        let ref = FIRDatabase.database().reference().child("survey/\(surveyID)/answers/\(userUid())")
        ref.child("alias").setValue((self.surveyAnswerName.text)!)
        ref.child("selectedID").setValue(self.selectedID)
        ref.child("displayname").setValue(userDisplayName())
        ref.child("suggest").setValue((self.suggestion.text)!)
        
        let ref2 = FIRDatabase.database().reference().child("user/\(userUid())/answers/\(surveyID)")
        ref2.child("creatorDisplayname").setValue(self.surveyDisplayName.text)
        ref2.child("endOfSurveyTime").setValue(self.endOfSurveyTime)
        ref2.child("topic").setValue(self.topic.text)
        ref2.child("select").setValue(self.selected.text)
        
        
        self.performSegue(withIdentifier: "gotoMonitorSurveyStatus", sender: self)
    }
    
    
    //看結果
    @IBAction func viewStatus(_ sender: Any) {
        
          self.performSegue(withIdentifier: "gotoMonitorSurveyStatus", sender: self)
    }
    
    
    
    //使用匿名
    @IBAction func surveyAnswerNameSwitch(_ sender: UISegmentedControl) {
        
        
        
        switch sender.selectedSegmentIndex {
        case 0:
            self.surveyAnswerName.isEnabled = false
            self.surveyAnswerName.backgroundColor = UIColor.clear
        default:
            self.surveyAnswerName.isEnabled = true
            self.surveyAnswerName.backgroundColor = UIColor.white
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoMonitorSurveyStatus"{
            let vc = segue.destination as! SurveyMonitorViewController
            vc.suveryID = self.surveyID
            vc.surveyEndTime = self.endOfSurveyTime
            vc.surveyTopic = self.topic.text!
            vc.surveyCreatorName = self.surveyDisplayName.text!
            vc.options = [ (option1.titleLabel?.text)!
                            ,(option2.titleLabel?.text)!
                            ,(option3.titleLabel?.text)!
                            ,(option4.titleLabel?.text)!
                            ,(option5.titleLabel?.text)!]
            vc.numberOfOption = numberOfOption
            vc.showID = self.surveyShowID.text!
            
        }
    }
    

        
        
    
}
