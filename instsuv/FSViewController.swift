//
//  FSViewController.swift
//  instsuv
//
//  Created by 申潤五 on 2016/12/16.
//  Copyright © 2016年 申潤五. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import MapKit

class FSViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {
    @IBOutlet weak var answerMap: UIButton!
    

    
    @IBOutlet weak var surveyCode: UITextField!

    @IBOutlet weak var mySurveyList: UITableView!
    
    @IBOutlet weak var surveryMap: MKMapView!
    var selectedSuveryID:String=""
    
    var locationManager:CLLocationManager? = CLLocationManager()

    var mapItems:Dictionary<String,Any> = Dictionary<String,Any>()
    
    var surveyDataSource:Array<Any>?
    var surveyIndex:Array<Any>?

    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager?.requestWhenInUseAuthorization()
        surveryMap.showsUserLocation = true
        surveryMap.delegate = self
        

        
        
        //xib的名稱
        let nib = UINib(nibName: "surveyListCell", bundle: nil)
        
        //註冊，forCellReuseIdentifier是你的TableView裡面設定的Cell名稱
        mySurveyList.register(nib, forCellReuseIdentifier: "SuveryTableCell")
        
        
        
        mySurveyList.delegate = self
        mySurveyList.dataSource = self
        
        
        updateSurveyMap()
        
//        let ref = FIRDatabase.database().reference().child("survey/idlist/10000")
//        updateSurveyListView(surveyTableDBref:  ref)

    }
    
    
    
    @IBAction func checkSurvey(_ sender: UIButton) {
        
        if surveyCode.text != "" {
            let ref = FIRDatabase.database().reference().child("survey/idlist/\(surveyCode.text!)")
           
            updateSurveyListView(surveyTableDBref:  ref)
        }else{
            showAlert(message: "請輸入代碼！")
        }

    }

    @IBAction func surveyMap(_ sender: UIButton) {
        updateSurveyMap()
    }
    
    @IBAction func systemSurvey(_ sender: UIButton) {
        updateSurveyListView(surveyTableDBref:  FIRDatabase.database().reference().child("survey/idlist/10000"))
    }
    
    @IBAction func usingHistory(_ sender: UIButton) {
        let userID = (FIRAuth.auth()?.currentUser?.uid)!
        let ref = FIRDatabase.database().reference().child("user/\(userID)/answers")
        updateSurveyListView(surveyTableDBref: ref)
    }
    
    @IBAction func mineSurvey(_ sender: UIButton) {
        let userID = (FIRAuth.auth()?.currentUser?.uid)!
        let ref = FIRDatabase.database().reference().child("user/\(userID)/mySurvey")
        updateSurveyListView(surveyTableDBref: ref)
        
    }
    
    //宣告這個UITableView畫面上的控制項總共有多少Row
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.surveyDataSource != nil
        {
            return (self.surveyDataSource?.count)!
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt: IndexPath){
        if let item = self.surveyIndex?[didSelectRowAt.row] as? String{
            self.selectedSuveryID=item
        }
        self.performSegue(withIdentifier: "gotoFillSurvey", sender: "Start")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoFillSurvey"{
            let vc = segue.destination as! FillSurveyViewController
            vc.surveyID = self.selectedSuveryID
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mySurveyList.dequeueReusableCell(withIdentifier: "SuveryTableCell") as! SurveyListTableViewCell
        
        
        if let item = self.surveyDataSource?[indexPath.row] as? NSDictionary{
           
            
            cell.surveyTopic.text = item.object(forKey: "topic") as? String

            
            print(cell.surveyTopic.text)
            
            
            cell.creatorDisplayName.text = item.object(forKey: "creatorDisplayname") as? String
            let endOfSurvey = self.nToDate(datenumber: Int64((item.object(forKey: "endOfSurveyTime") as! String))!)
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = "M/dd HH:mm"
            cell.endSurveyTime.text = formatter.string(from: endOfSurvey as Date)
            
            if Date().compare(endOfSurvey) == ComparisonResult.orderedDescending{
                cell.endSurveyTime.backgroundColor = UIColor.yellow
            }
            
        }

        return cell
    }
    
    
    func updateSurveyMap(){
        
        self.surveryMap.isHidden = false
        
        let now = locationManager?.location?.coordinate
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegionMake(now!, span)
        surveryMap.setRegion(region, animated: true)
        surveryMap.mapType = .standard
        
        
        let ref = FIRDatabase.database().reference().child("/survey/locationList")
        showWaiting()
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
        
            let count = snapshot.childrenCount
            if count == 0 {
                self.showAlert(message: "查無資料！")
                self.stopWaiting()
                return
            }
            
            self.mapItems = Dictionary<String,Any>()
            let values = snapshot.value as! NSDictionary
            
            for item in values{
                // 這兒應該加上過期移除裝問卷
                //
                //
                
                
                
                self.mapItems[item.key as! String] = item.value as! NSDictionary
                print("\(item.key as! String),,,,,\(item.value)")
                print(self.mapItems.count)
                
                
                
                
                let annotation = MKPointAnnotation()
                let theSuvey = item.value as! NSDictionary
                let la = theSuvey.value(forKey: "la") as! CLLocationDegrees
                let ro = theSuvey.value(forKey: "lo") as! CLLocationDegrees
                // 是不是應該比較只放附近的座標？
                let theSurveyLocation = CLLocationCoordinate2DMake(la, ro)
                annotation.title = theSuvey.value(forKey: "topic") as? String
                let eod = self.nToDate(datenumber: Int64((theSuvey.value(forKey: "endOfSurveyTime") as? String)!)!)
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "YYYY-MM-dd hh:mm"
                let dateString = dateFormat.string(from: eod)
                annotation.subtitle = dateString
                annotation.coordinate = theSurveyLocation
                annotation.accessibilityLabel = item.key as! String
                self.surveryMap.addAnnotation(annotation)
                
                
            }
            
            self.stopWaiting()
        }){(error) in
            self.stopWaiting()
        }
        

    }
    
    
    func location(){
        print("Test")
    }
    
    func updateSurveyListView(surveyTableDBref:FIRDatabaseReference){
        self.answerMap.isHidden = true
        self.surveryMap.isHidden = true
        showWaiting()
        surveyTableDBref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            
            let count=snapshot.childrenCount
            if count == 0 {
                self.showAlert(message: "查無資料！")
                self.stopWaiting()
                return
            }
            
            let values = snapshot.value as! NSDictionary
            self.surveyDataSource=[NSDictionary]()
            self.surveyIndex=[String]()
 
            for theItem in values{
                self.surveyIndex?.append(theItem.key)
                self.surveyDataSource?.append(theItem.value)
            }
            self.mySurveyList.reloadData()
            self.stopWaiting()
            
        }) { (error) in
            
        }  
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.answerMap.isHidden = false
        
        for item in self.mapItems{
            let itemValue = item.value as! NSDictionary
            if itemValue.value(forKey: "la") as! CLLocationDegrees == view.annotation?.coordinate.latitude &&
                itemValue.value(forKey: "lo") as! CLLocationDegrees == view.annotation?.coordinate.longitude
                {
                    self.selectedSuveryID = item.key
                    break
                }
        }
        
        
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        self.answerMap.isHidden = true
    }
    

    @IBAction func selectMapSurvey(_ sender: UIButton) {
    
        self.performSegue(withIdentifier: "gotoFillSurvey", sender: "Start")
    }
    
}
