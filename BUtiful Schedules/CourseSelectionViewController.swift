//
//  CourseSelectionViewController.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/20/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit
import Alamofire
import Kanna

class CourseSelectionViewController: UIViewController {
    
    let unknownChar = " " //NOT SPACE, ASCII CODE 160 aka. &nbsp;
    
    @IBOutlet weak var goButton: UIButton!
    
    var courseSize: Int? = 5
    var courseFields = [CourseView]()
    var coursesParsed = 0
    var startTime = Date().timeIntervalSince1970
    var endTime : TimeInterval?
    var progressView : UIProgressView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Do any additional setup after loading the view.
        let screenSize: CGRect = UIScreen.main.bounds
        NotificationCenter.default.addObserver(self, selector: #selector(CourseSelectionViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//        
//        for i in 0..<courseSize! {
//            let view = CourseView(frame: CGRect(x: 0, y: 81 + (i*40), width: Int(screenSize.width), height:40), screenWidth: Int(screenSize.width), controller: self, index: i)
//            courseFields += [view]
//            self.view.addSubview(view)
//        }
        
        (self.view as! UIScrollView).autoresizingMask = UIViewAutoresizing.flexibleHeight
        courseFields[0].becomeFirstResponder()
        simulate()
        
    }
    
    func chooseNextResponder(_ index: Int) {
        if index < courseSize! {
            courseFields[index].becomeFirstResponder();
        }
    }
    
    func keyboardWillShow(_ notification:Notification) {
        let userInfo:NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        let screenSize: CGRect = UIScreen.main.bounds
        
        (self.view! as! UIScrollView).contentSize = CGSize(width: Int(screenSize.width), height: 61 + courseSize! * 40 + Int(keyboardHeight))
    }
    
    @IBAction func goButtonPressed(_ sender: AnyObject) {
        //TODO validate all fields
        coursesParsed = 0
//        CourseList.reset()
        for i in 0..<courseSize! {
            let courseInfo = courseFields[i].getCourseInfo()
            makeGetRequestForCourse(courseInfo)
        }
        
        //  Just create your alert as usual:
        let alertView = UIAlertController(title: "Loading Class Data...", message: "", preferredStyle: .alert)
        
        //  Show it to your users
        present(alertView, animated: true, completion: {
            //  Add your progressbar after alert is shown (and measured)
            let margin:CGFloat = 16.0
            let rect = CGRect(x: margin, y: 50.0, width: alertView.view.frame.width - margin * 2.0 , height: 2.0)
            self.progressView = UIProgressView(frame: rect)
            self.progressView!.progress = Float(self.coursesParsed) / Float(self.courseSize!)
            self.progressView!.tintColor = UIColor.red
            alertView.view.addSubview(self.progressView!)
        })
    }
    
    func makeGetRequestForCourse(_ courseInfo: [String]) {
        var URL = ""
        if (courseInfo.count == 3) {
            URL = "https://www.bu.edu/link/bin/uiscgi_studentlink.pl/1447905455?ModuleName=univschr.pl&SearchOptionDesc=Class+Number&SearchOptionCd=S&KeySem=20173&ViewSem=Fall+2016&College=\(courseInfo[0])&Dept=\(courseInfo[1])&Course=\(courseInfo[2])"
        } else if courseInfo.count == 4{
            URL = "https://www.bu.edu/link/bin/uiscgi_studentlink.pl/1447905455?ModuleName=univschr.pl&SearchOptionDesc=Class+Number&SearchOptionCd=S&KeySem=20173&ViewSem=Fall+2016&College=\(courseInfo[0])&Dept=\(courseInfo[1])&Course=\(courseInfo[2])&Section=\(courseInfo[3])"
        }
        Alamofire.request(URL)
            .responseString { response in
                //print(response.result.value) // URL response
                self.parseHTMLForClass(response.result.value!, courseInfo: courseInfo)
        }
    }
    
    func parseHTMLForClass(_ html: String, courseInfo: [String]) {
        if let doc = Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
            var condition : String?
            for row in doc.css("body > table")[3].css("tr") {
                //Selects condition row
                
                if row.at_css("table") != nil {
                    var conditionText = row.text!.regexMatches("must(.)*\\W([A-Z]){1}([0-9]){1}")
                    if conditionText.count > 0 {
                        //TODO multiple conditions in multiple rows?
                        condition = conditionText[0]
                    }
                    
                } else if row.innerHTML!.range(of: courseInfo[0] + unknownChar + courseInfo[1] + courseInfo[2]) != nil {
                    //Parses course info
                    var sectionInfo = parseCourseLine(row)
                    if let foundCondition = condition {
//                        must also register for a discussion section B2-B3 and a lab section A2 or A5 -> "B2-B3|A2 or A5"
                        let conditionSections = foundCondition.regexMatches("[A-Z]{1}[0-9]{1}.*[A-Z]{1}[0-9]{1}").joined(separator: "|")
                        sectionInfo += [conditionSections]
                        condition = nil
                    }
//                    print(sectionInfo)
//                    CourseList.add(sectionInfo, index: viewInde)
                }
            }
            
            var nextCourse = [
                doc.css("input[name='College']")[0].toHTML?.regexMatches("value=\"\\w{3}")[0],
                doc.css("input[name='Dept']")[0].toHTML?.regexMatches("value=\"\\w{2}")[0],
                doc.css("input[name='Course']")[0].toHTML?.regexMatches("value=\"\\w{3}")[0],
                doc.css("input[name='Section']")[0].toHTML?.regexMatches("value=\"\\w{2}")[0]
            ]
            nextCourse = nextCourse.map({$0?.replacingOccurrences(of: "value=\"", with: "")})
                        
            if let nextCourseColl = nextCourse[0], let nextCourseDept = nextCourse[1], let nextCourseSec = nextCourse[2] {
                
                if nextCourseColl == courseInfo[0] && nextCourseDept == courseInfo[1] && nextCourseSec == courseInfo[2] {
                    makeGetRequestForCourse(nextCourse.map({$0!}))
                } else {
                    coursesParsed += 1
                    if let view = progressView {
                        view.progress = Float(coursesParsed) / Float(courseSize!)
                    }
                }
            } else {
                coursesParsed += 1
                if let view = progressView {
                    view.progress = Float(coursesParsed) / Float(courseSize!)
                }
            }
        } else {
            //TODO error checking?
        }
        if (coursesParsed == courseSize) {
            startTime = Date().timeIntervalSince1970
            CourseList.findWorkingSchedules()
            endTime = Date().timeIntervalSince1970
            if let time = endTime {
                print(time)
                print(startTime)
                print(time-startTime)
            }
            self.dismiss(animated: true, completion: nil)
            self.performSegue(withIdentifier: "schedulesSegue", sender: self)
        }
        
    }
    
    func parseCourseLine(_ node: XMLElement) -> [String] {
        var i = 0
        var sectionInfo = [String]()
        for text in node.css("font") {
            if (i == 0 || i == 3 || i == 4 || i == 12) {
                i += 1
                continue
            } else if (i == 1) {
                //ex. CAS EC101 A1 -> ["CAS EC101", "A1"]
                sectionInfo +=
                    [text.text!.regexMatches(".+\\d{3}")[0], String(text.text!.characters.suffix(2))]
            } else if (i == 2) {
                //ex. Intro Micro<br><a...>Watson</a> -> ["Watson"]
                sectionInfo += [text.innerHTML!.regexMatches("<br>.+")[0].replacingOccurrences(of: "<br>", with: "").replaceRegex("<a.+\">|<\\/a>", withString:"")!]
            } else if (i == 7) {
                //ex. <a....></a>PHO<br>ARR... -> ["PHO<br>ARR"]
                sectionInfo += [text.innerHTML!.trim().replaceRegex("<a.+\">|<\\/a>", withString:"")!]
            } else {
                //ex. ["Discussion"] or ["Mon,Wed<br>Fri"]
                sectionInfo += [text.innerHTML!.trim()]
            }
            
            i += 1
            
        }
        return sectionInfo
        
    }
    
    
//     // MARK: - Navigation
//     
//     // In a storyboard-based application, you will often want to do a little preparation before navigation
//     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//     // Get the new view controller using segue.destinationViewController.
//     // Pass the selected object to the new view controller.
//        print(segue.identifier)
//     }
    
    
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    /*
     Important Test Case:
        ENG EK 127
        ENG EK 128
    */
    
    func simulate() {
        
//        courseFields[0].collegeField?.text = "CAS"
//        courseFields[0].deptField?.text = "EC"
//        courseFields[0].courseField?.text = "101"
        
        
//        courseFields[0].collegeField?.text = "ENG"
//        courseFields[0].deptField?.text = "EK"
//        courseFields[0].courseField?.text = "128"
        
        
//        courseFields[0].collegeField?.text = "ENG"
//        courseFields[0].deptField?.text = "EC"
//        courseFields[0].courseField?.text = "330"
//
//        courseFields[1].collegeField?.text = "ENG"
//        courseFields[1].deptField?.text = "EC"
//        courseFields[1].courseField?.text = "440"
        
        
        courseFields[0].collegeField?.text = "CAS"
        courseFields[0].deptField?.text = "EC"
        courseFields[0].courseField?.text = "101"
        
        courseFields[1].collegeField?.text = "ENG"
        courseFields[1].deptField?.text = "EC"
        courseFields[1].courseField?.text = "330"
        
        courseFields[2].collegeField?.text = "ENG"
        courseFields[2].deptField?.text = "EC"
        courseFields[2].courseField?.text = "381"
        
        courseFields[3].collegeField?.text = "SMG"
        courseFields[3].deptField?.text = "AC"
        courseFields[3].courseField?.text = "221"
        
        courseFields[4].collegeField?.text = "CAS"
        courseFields[4].deptField?.text = "MA"
        courseFields[4].courseField?.text = "193"
        
//        courseFields[0].collegeField?.text = "CAS"
//        courseFields[0].deptField?.text = "EC"
//        courseFields[0].courseField?.text = "101"
//        courseFields[1].collegeField?.text = "ENG"
//        courseFields[1].deptField?.text = "EC"
//        courseFields[1].courseField?.text = "330"
        
        
        courseSize = 5
        goButton.sendActions(for: UIControlEvents.touchUpInside)
    }
    
}
