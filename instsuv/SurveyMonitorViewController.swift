//
//  SurveyMonitorViewController.swift
//  instsuv
//
//  Created by 申潤五 on 2016/12/20.
//  Copyright © 2016年 申潤五. All rights reserved.
//

import UIKit
import Firebase
import Charts
import RealmSwift


class SurveyMonitorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var answersTable: UITableView!
    @IBOutlet weak var topic: UILabel!
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var surveyShowID: UILabel!
    
    @IBOutlet weak var chartView: PieChartView!
    
    var answersDataSource:Array<Any>=[NSDictionary]()
    
    var suveryID = ""
    var surveyTopic = ""
    var surveyCreatorName = ""
    var surveyEndTime = ""
    var options:[String] = []
    var numberOfOption = 0
    var showID = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.showWaiting()
        

        
        let nib = UINib(nibName:"AnswerTableViewCell", bundle: nil)
        answersTable.register(nib, forCellReuseIdentifier: "AnswerTableCell")
        answersTable.delegate = self
        answersTable.dataSource = self

        topic.text = self.surveyTopic
        let endDate = self.nToDate(datenumber: Int64(self.surveyEndTime)!)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "M/dd HH:mm"
        header.text = "結束時間：\(formatter.string(from: endDate)) 建立者：\(self.surveyCreatorName)"
        
        
        surveyShowID.text = showID
        //設定圖表
         chartView.noDataText = ""
        

        
        
        
        
        let ref = FIRDatabase.database().reference().child("survey/\(suveryID)/answers")
        
        if getDateInt(date: Date()) < Int64(surveyEndTime)! {
        
            ref.observe(.value, with: { (snapshot) in
                if snapshot.childrenCount == 0{
                    self.showAlert(message: "尚無人回答問題！")
                    self.stopWaiting()
                }else{
                    self.answersDataSource = [NSDictionary]()
                    if let answers = snapshot.value as! NSDictionary?{
                        for answer in answers{
                                self.answersDataSource.append(answer.value)
                        }
                    }
                    self.answersTable.reloadData()
                    self.reloadChart()
                }
                
            })
        
        }else{
        
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.childrenCount == 0{
                    self.showAlert(message: "尚無人回答問題！")
                    self.stopWaiting()
                }else{
                    self.answersDataSource = [NSDictionary]()
                    if let answers = snapshot.value as! NSDictionary?{
                        for answer in answers{
                            self.answersDataSource.append(answer.value)
                        }
                    }
                    self.answersTable.reloadData()
                    self.reloadChart()
                }
                
            })
            
            
        }


        // Do any additional setup after loading the view.
    }
    
    
    func reloadChart() {
        
        self.stopWaiting()
        var answerCount:[Int] = [0,0,0,0,0]
        
        for i in 0..<answersDataSource.count{
            let selected = Int((answersDataSource[i] as! NSDictionary).object(forKey: "selectedID") as! String)!
            switch selected {
            case 1:
                answerCount[0] += 1
            case 2:
                answerCount[1] += 1
            case 3:
                answerCount[2] += 1
            case 4:
                answerCount[3] += 1
            case 5:
                answerCount[4] += 1
            default:break
            }
        }
        
        

        chartView.backgroundColor = UIColor.white

        var dataEntries:[PieChartDataEntry] = []
        for i in 0..<numberOfOption{
            let value = Double( answerCount[i])
            if value > 0 {
                let dataEntry = PieChartDataEntry(value: value, label: "\(i+1):\(options[i])")
                dataEntries.append(dataEntry)
            }
        }
        
        
        
        let chartDataSet = PieChartDataSet(values: dataEntries, label: "")
        
        chartDataSet.colors = ChartColorTemplates.colorful()
        let chartData = PieChartData(dataSet: chartDataSet)
        

        chartView.centerText = "比例圖"
        chartView.animate(xAxisDuration: 3)


        chartView.data = chartData
        
        
    }
    


    @IBAction func Back(_ sender: UIButton) {
        let superVC = self.navigationController?.popViewController(animated: true)
        _ = superVC?.navigationController?.popViewController(animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.answersDataSource.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 53.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt: IndexPath){
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = answersTable.dequeueReusableCell(withIdentifier: "AnswerTableCell") as! AnswerTableViewCell
        
        if let answerData = answersDataSource[indexPath.row] as? NSDictionary{
            cell.answerDisplayName.text = answerData.object(forKey: "alias") as? String
            cell.answerSelectID.text = answerData.object(forKey: "selectedID") as? String
            cell.answerSuggest.text = answerData.object(forKey: "suggest") as? String
        
        }
        return cell
    }

    
        
//    }

    
}
