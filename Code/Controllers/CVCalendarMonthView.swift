//
//  CVCalendarMonthView.swift
//  CVCalendar
//
//  Created by E. Mozharovsky on 12/26/14.
//  Copyright (c) 2014 GameApp. All rights reserved.
//

import UIKit

class CVCalendarMonthView: UIView {
    // MARK: - Non public properties
    private var interactiveView: UIView!
    
    override var frame: CGRect {
        didSet {
            if let calendarView = calendarView {
                if calendarView.calendarMode == CalendarMode.MonthView {
                    updateInteractiveView()
                }
            }
        }
    }
    
    private var touchController: CVCalendarTouchController {
        return calendarView.touchController
    }
    
    // MARK: - Public properties
    
    weak var calendarView: CVCalendarView!
    var date: NSDate!
    var numberOfWeeks: Int!
    var weekViews: [CVCalendarWeekView]!
    
    var weeksIn: [[Int : [Int]]]?
    var weeksOut: [[Int : [Int]]]?
    var currentDay: Int?
    
    var ranged = false
    
    // MARK: - Initialization
    
    init(calendarView: CVCalendarView, date: NSDate) {
        super.init(frame: CGRectZero)
        self.calendarView = calendarView
        self.date = date
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func mapDayViews(body: (DayView) -> Void) {
        for weekView in self.weekViews {
            for dayView in weekView.dayViews {
                body(dayView)
            }
        }
    }
}

// MARK: - Creation and destruction

extension CVCalendarMonthView {
    func commonInit() {
        let calendarManager = calendarView.manager
        safeExecuteBlock({
            self.numberOfWeeks = calendarManager.monthDateRange(self.date).countOfWeeks
            self.weeksIn = calendarManager.weeksWithWeekdaysForMonthDate(self.date).weeksIn
            self.weeksOut = calendarManager.weeksWithWeekdaysForMonthDate(self.date).weeksOut
            self.currentDay = Manager.dateRange(NSDate()).day
            }, collapsingOnNil: true, withObjects: date)
    }
}

// MARK: Content reload

extension CVCalendarMonthView {
    func reloadViewsWithRect(frame: CGRect) {
        self.frame = frame
        
        let renderer = calendarView.renderer
        
        safeExecuteBlock({
            for (index, weekView) in self.weekViews.enumerate() {
                let frame = renderer.renderWeekFrameForMonthView(self, weekIndex: index)
                weekView.frame = frame
                weekView.reloadDayViews()
            }
            }, collapsingOnNil: true, withObjects: weekViews)
    }
}

// MARK: - Content fill & update

extension CVCalendarMonthView {
    func updateAppearance(frame: CGRect) {
        self.frame = frame
        createWeekViews()
    }
    
    func createWeekViews() {
        let renderer = calendarView.renderer
        weekViews = [CVCalendarWeekView]()
        
        safeExecuteBlock({
            for i in 0..<self.numberOfWeeks! {
                let frame = renderer.renderWeekFrameForMonthView(self, weekIndex: i)
                let weekView = CVCalendarWeekView(monthView: self, frame: frame, index: i)
                
                self.safeExecuteBlock({
                    self.weekViews!.append(weekView)
                    }, collapsingOnNil: true, withObjects: self.weekViews)
                
                self.addSubview(weekView)
            }
            }, collapsingOnNil: true, withObjects: numberOfWeeks)
    }
}

// MARK: - Interactive view management & update

extension CVCalendarMonthView {
    func updateInteractiveView() {
        safeExecuteBlock({
            let mode = self.calendarView!.calendarMode!
            if mode == .MonthView {
                if let interactiveView = self.interactiveView {
                    interactiveView.frame = self.bounds
                    interactiveView.removeFromSuperview()
                    self.addSubview(interactiveView)
                } else {
                    self.interactiveView = UIView(frame: self.bounds)
                    self.interactiveView.backgroundColor = .clearColor()
                    
                    let tapRecognizer = UITapGestureRecognizer(target: self, action: "didTouchInteractiveView:")
                    let pressRecognizer = UILongPressGestureRecognizer(target: self, action: "didPressInteractiveView:")
                    pressRecognizer.minimumPressDuration = 0.3
                    
                    self.interactiveView.addGestureRecognizer(pressRecognizer)
                    self.interactiveView.addGestureRecognizer(tapRecognizer)
                    
                    self.addSubview(self.interactiveView)
                }
            }
            
            }, collapsingOnNil: false, withObjects: calendarView)
    }
    
    func didPressInteractiveView(recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.locationInView(self.interactiveView)
        let state: UIGestureRecognizerState = recognizer.state
        
        switch state {
        case .Began:
            touchController.receiveTouchLocation(location, inMonthView: self, withSelectionType: .Range(.Started))
        case .Changed:
            touchController.receiveTouchLocation(location, inMonthView: self, withSelectionType: .Range(.Changed))
        case .Ended:
            touchController.receiveTouchLocation(location, inMonthView: self, withSelectionType: .Range(.Ended))
            
        default: break
        }
    }
    
    func didTouchInteractiveView(recognizer: UITapGestureRecognizer) {
        let location = recognizer.locationInView(self.interactiveView)
        touchController.receiveTouchLocation(location, inMonthView: self, withSelectionType: .Single)
    }
}

// MARK: - Safe execution

extension CVCalendarMonthView {
    func safeExecuteBlock(block: Void -> Void, collapsingOnNil collapsing: Bool, withObjects objects: AnyObject?...) {
        for object in objects {
            if object == nil {
                if collapsing {
                    fatalError("Object { \(object) } must not be nil!")
                } else {
                    return
                }
            }
        }
        
        block()
    }
}