//
//  UniversalExtentions.swift
//  iLogs - Swift
//
//  Created by Erick Sanchez on 9/26/17.
//  Copyright © 2017 Erick Sanchez. All rights reserved.
//

import Foundation
import UIKit

struct IfError {
    @discardableResult
    init?(_ error: Error?) {
        if let err = error {
            assertionFailure(err.localizedDescription)
            return nil
        }
    }
    
    @discardableResult
    init?(_ error: Error?, handler: (Error) -> Void) {
        if let err = error {
            assertionFailure(err.localizedDescription)
            handler(err)
            return nil
        }
    }
}

enum CRUD {
    case Create
    case Read
    case Update
    case Delete
    
    var isCreating: Bool {
        return self == .Create
    }
    
    var isReading: Bool {
        return self == .Read
    }
    
    var isUpdating: Bool {
        return self == .Update
    }
    
    var isDeleting: Bool {
        return self == .Delete
    }
}

enum CopyOptions<T> {
    case All
    case Some([T])
    case None
}

extension SignedInteger {
    var isEven: Bool {
        return self % 2 == 0
    }
}

extension UIColor {
    class var lighterGray: UIColor {
        return UIColor(white: 0.98, alpha: 1)
    }
    
    class var disabledGray: UIColor {
        return UIColor(displayP3Red: 151.0/255.0, green: 151.0/255.0, blue: 151.0/255.0, alpha: 1.0)
    }
    
    class var destructive: UIColor {
        return UIColor(displayP3Red: 255/255, green: 56.0/255.0, blue: 36.0/255.0, alpha: 1)
    }
    
    //FIXME: store the empty view? or create it every time this property is read
    static var buttonTint: UIColor = {
        let view = UIView()
        
        return view.tintColor
    }()
}

private enum WeekdayRange {
    case First
    case Last
}

public struct WordDescriptor {
    var shorter: String?
    var short: String?
    var `default`: String
    var long: String?
    var longer: String?
}

extension NSSortDescriptor {
    static func localizedStandardCompare(with key: String, ascending: Bool = false) -> NSSortDescriptor {
        return NSSortDescriptor(key: key, ascending: ascending, selector: #selector(NSString.localizedStandardCompare(_:)))
    }
}

extension NSMutableAttributedString {
    convenience init(strikedOut string: String) {
        self.init(string: string)
        #if swift(>=4.0)
            self.addAttribute(NSAttributedStringKey.strikethroughStyle, value: 2, range: NSMakeRange(0, string.count))
        #else
            self.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, string.count))
        #endif
    }
}

extension String {
    init?(doubledCurrency value: Double) {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        if let string = formatter.string(from: NSNumber(value: value)) {
            self = string
        } else {
            return nil
        }
    }
}

// TODO : may not work on other locals
let CTDateComponentMinute: TimeInterval = 60
let CTDateComponentHour: TimeInterval = CTDateComponentMinute*60
let CTDateComponentDay: TimeInterval = CTDateComponentHour*24
let CTDateComponentWeek: TimeInterval = CTDateComponentDay*7

extension String {
    init(date: NSDate, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .none) {
        #if swift(>=4.0)
            self.init(DateFormatter.localizedString(from: date as Date, dateStyle: dateStyle, timeStyle: timeStyle))
        #else
            self.init(DateFormatter.localizedString(from: date as Date, dateStyle: dateStyle, timeStyle: timeStyle))!
        #endif
    }
    
    init(date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .none) {
        self = String(date: date as NSDate, dateStyle: dateStyle, timeStyle: timeStyle)
    }
    
    /*
     Formats the number of seconds into units providedas
     3600 seconds is "1h 0m 0s"
     */
    init(timeInterval: TimeInterval) {
        self.init(timeInterval: timeInterval, units: .weekday, .day, .hour, .minute, .second)
    }
    
    init(timeInterval: TimeInterval, units: Calendar.Component...) {
        let options = TimeIntervalOptions(units: units, unitWindowSize: 0)
        
        self.init(timeInterval: timeInterval, options: options)
    }
    
    struct TimeIntervalOptions {
        var units: [Calendar.Component]
        var unitWindowSize: Int = 0
        var textInterpolation: (Int, WordDescriptor) -> (String)
        
        init(units: [Calendar.Component], unitWindowSize: Int, textInterpolation: @escaping (Int, WordDescriptor) -> (String) = { "\($0)\($1.shorter!) " }) {
            self.units = units
            self.unitWindowSize = unitWindowSize
            self.textInterpolation = textInterpolation
        }
        
        /** only displaying time; hour, minute and second */
        static var time: TimeIntervalOptions {
            return .init(units: [.hour, .minute, .second], unitWindowSize: 0)
        }
        
        /** window size of 2 only displaying hour, minute and second */
        static var largestTwoTime: TimeIntervalOptions {
            return .init(units: [.hour, .minute, .second], unitWindowSize: 2)
        }
        
        /** window size of 2 only displaying day, hour and mintue */
        static var largestTwoUnits: TimeIntervalOptions {
            return .init(units: [.day, .hour, .minute], unitWindowSize: 2)
        }
    }
    
    init(timeInterval: TimeInterval, options: TimeIntervalOptions) {
        var nSeconds = abs(Int(timeInterval))
        
        var string = ""
        var currentWindowSize = 1
        
        let dateComponentScales = DateComponents.ComponentScales
        
        //TODO Months
        for aUnit in options.units {
            if options.unitWindowSize != 0, currentWindowSize > options.unitWindowSize {
                break
            }
            
            if let scaleInfo = dateComponentScales[aUnit] {
                if aUnit == .second {
                    if nSeconds > 0 {
                        //TODO: puralization
                        string.append(options.textInterpolation(nSeconds, scaleInfo.character))
                    }
                } else {
                    let unitCount = nSeconds/Int(scaleInfo.scale)
                    nSeconds -= unitCount*Int(scaleInfo.scale)
                    if unitCount > 0 {
                        let text = options.textInterpolation(unitCount, scaleInfo.character)
                        
                        //TODO: puralization
                        string.append(text)
                        currentWindowSize += 1
                    }
                }
            }
        }
        
        // If no units were added to string, add the smallest unit with the count
        //of zero
        if string == "" {
            if let smallestUnit = options.units.last,
                let scaleInfo = dateComponentScales[smallestUnit] {
                
                self = options.textInterpolation(0, scaleInfo.character)
                
            // Error? return the empty string
            } else {
                self = string
            }
        } else {
            self = string
        }
    }
}

extension UITableView {
    func headerLabel(forSection section: Int) -> UILabel? {
        return self.headerView(forSection: section)?.contentView.subviews.first as! UILabel?
    }
    func footerLabel(forSection section: Int) -> UILabel? {
        return self.footerView(forSection: section)?.contentView.subviews.first as! UILabel?
    }
}

extension DateComponents {
    static let AllComponents: Set<Calendar.Component> = [.era,.year,.month,.day,.hour,.minute,.second,.weekday,.weekdayOrdinal,.quarter,.weekOfMonth,.weekOfYear,.yearForWeekOfYear,.nanosecond,.calendar,.timeZone]
    
    static let ComponentScales: [Calendar.Component: (scale: TimeInterval, character: WordDescriptor)] = [
        .second: (1, WordDescriptor(shorter: "s", short: "sec", default: "Second", long: nil, longer: nil)),
        .minute: (CTDateComponentMinute, WordDescriptor(shorter: "m", short: "min", default: "Minute", long: nil, longer: nil)),
        .hour: (CTDateComponentHour, WordDescriptor(shorter: "h", short: "hr", default: "Hour", long: nil, longer: nil)),
        .day: (CTDateComponentDay, WordDescriptor(shorter: "d", short: "day", default: "Day", long: nil, longer: nil)),
        .weekday: (CTDateComponentWeek, WordDescriptor(shorter: "w", short: "wk", default: "Week", long: nil, longer: nil))
    ]
    static let DayComponents: Set<Calendar.Component> = [.year,.month,.day]
    static let TimeComponents: Set<Calendar.Component> = [.hour,.minute,.second]
    
    init(date: Date, forComponents components: Set<Calendar.Component>)  {
        self = Calendar.current.dateComponents(components, from: date)
    }
    
    var dateValue: Date? {
        return Calendar.current.date(from: self)
    }
    
    /** returns the length in time, seconds+mintues+hours only */
    var timeInterval: TimeInterval {
        get {
            var interval: TimeInterval = 0
            if let _second = second {
                interval += TimeInterval(_second)
            }
            if let _minute = minute {
                interval += TimeInterval(_minute)*CTDateComponentMinute
            }
            if let _hour = hour {
                interval += TimeInterval(_hour)*CTDateComponentHour
            }
            
            return interval
        }
    }
    
    /** requires weekday and the calendar */
    var weekdayTitle: String? {
        if let weekdaySymbols = calendar?.weekdaySymbols {
            if let day = weekday {
                return weekdaySymbols[day - 1]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

extension Date {
    /*
     returns today's date with hour = minute = second = 0. Use `intervale = 0`
     to return midnight
     */
    init(timeIntervalSinceMidnight interval: TimeInterval) {
        var components = DateComponents(date: Date(timeIntervalSinceNow: interval), forComponents: DateComponents.AllComponents)
        components.hour = 0
        components.minute = 0
        components.second = 0
        self = components.dateValue!.addingTimeInterval(interval)
    }
}

private func weekday(from sourceDate: Date, weekday: String? = nil, weekdayRange: WeekdayRange? = .First) -> Date {
    //assert(weekday == nil && weekdayRange == nil, "must use weekday or weekday range")
    
    let calendar = Calendar.current
    var dateComponents = DateComponents()
    let listOfWeekdays = calendar.weekdaySymbols
    if weekday != nil {
        dateComponents.weekday = listOfWeekdays.index(of: weekday!)
    } else {
        dateComponents.weekday = weekdayRange == .First ? 1 : listOfWeekdays.count
    }
    
    let sourceDateComponents = DateComponents(date: sourceDate, forComponents: [.weekday])
    
    if sourceDateComponents.weekday! == dateComponents.weekday! {
        return sourceDate
    }
    
    let direction: Calendar.SearchDirection
    if dateComponents.weekday! < sourceDateComponents.weekday! {
        direction = .backward
    } else {
        direction = .forward
    }
    
    let date = calendar.nextDate(after: sourceDate, matching: dateComponents, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: direction)!
    
    return date
}

extension Calendar {
    public func endOfDay(for date: Date) -> Date {
        let startOfDate = self.startOfDay(for: date)
        var components = DateComponents(date: startOfDate, forComponents: [.hour,.minute,.second])
        components.hour = 23
        components.minute = 59
        components.second = 59
     
        return components.date!
    }
}

extension UITextField {
    
    /**
     set the textfield's auto correction type to default and auto capitalization
     type to words and update the text and placeholder text
     */
    open func setStyleToParagraph(withPlaceholderText placeholder: String? = "", withInitalText text: String? = "") {
        self.autocorrectionType = .default
        self.autocapitalizationType = .words
        self.text = text
        self.placeholder = placeholder
        
    }
    
    /**
     <#Lorem ipsum dolor sit amet.#>
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     
     - returns: <#Sed do eiusmod tempor.#>
     */
    func isEmpty() -> Bool {
        return self.text != "" && self.text != nil
    }
    
}

public struct UIAlertActionInfo {
    var title: String?
    var style: UIAlertActionStyle
    var handler: ((UIAlertAction) -> Swift.Void)?
    
    init(title: String?, style: UIAlertActionStyle = .default, handler: ((UIAlertAction) -> Swift.Void)?) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

extension UIAlertController {
    open func addActions(cancelButton cancel: String? = "Cancel", actions: UIAlertActionInfo...) {
        for action in actions {
            self.addAction(UIAlertAction(title: action.title, style: action.style, handler: action.handler))
        }
        if cancel != nil {
            self.addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
        }
    }
    
    /**
     Adds a button with, or without an action closure with the given title
     
     - warning: the button's style is set to .default
     
     - returns: UIAlertController
     */
    public func addDismissableButton(title: String = "Dismiss", with action: @escaping (UIAlertAction) -> () = {_ in}) -> UIAlertController {
        return self.addButton(title: title, with: action)
    }
    
    /**
     Add a button with a title, style, and action.
     
     - warning: style and action defaults to .default and an empty closure body
     
     - returns: UIAlertController
     */
    public func addButton(title: String, style: UIAlertActionStyle = .default, with action: @escaping (UIAlertAction) -> () = {_ in}) -> UIAlertController {
        self.addAction(UIAlertAction(title: title, style: style, handler: action))
        
        return self
    }
    
    /**
     Add a textfield with the given text and placeholder text
     
     - warning: the newly added textfield invokes .setStyleToParagraph(..)
     
     - returns: UIAlertController
     */
    public func addTextField(defaultText: String? = nil, placeholderText: String? = nil) -> UIAlertController {
        self.addTextField(configurationHandler: { (textField) in
            textField.setStyleToParagraph(withPlaceholderText: placeholderText, withInitalText: defaultText)
        })
        
        return self
    }
    
    /**
     Add a button with the style set to .cancel.
     
     the default action is an empty closure body
     
     - returns: UIAlertController
     */
    public func addCancelButton(title: String = "Cancel", with action: @escaping (UIAlertAction) -> () = {_ in}) -> UIAlertController {
        return self.addButton(title: title, style: .cancel, with: action)
    }
    
    /**
     For the given viewController, present(..) invokes viewController.present(..)
     
     - warning: viewController.present(.., animiated: true, ..doc)
     
     - returns: Discardable UIAlertController
     */
    @discardableResult
    public func present(in viewController: UIViewController, completion: (() -> ())? = nil) -> UIAlertController {
        viewController.present(self, animated: true, completion: completion)
        
        return self
    }
    
    var inputField: UITextField {
        return self.textFields!.first!
    }
}

typealias UITextAlertController = UIAlertController

extension UITextAlertController {
    convenience init(title: String?, message: String?, textFieldConfig: ((UITextField) -> Void)?) {
        self.init(title: title, message: message, preferredStyle: .alert)
        
        self.addTextField(configurationHandler: textFieldConfig ?? { $0.setStyleToParagraph() })
    }
    
    /** this will insert a cancel action after the action */
    open func addConfirmAction(action: UIAlertActionInfo) {
        self.addActions(cancelButton: nil, actions: action)
        self.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    }
}

extension Bool {
    public mutating func invert() {
        if self == true {
            self = false
        } else {
            self = true
        }
    }
    
    public var inverse: Bool {
        if self == true {
            return false
        } else {
            return true
        }
    }
}

public extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    static let SettingViewDidAppear = "settings.viewDidAppear"
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public class func once(token: String, block: () -> Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}

extension UIButton {
    func setTitleWithoutAnimation(_ title: String?, for state: UIControlState) {
        UIView.performWithoutAnimation {
            self.setTitle(title, for: state)
            self.layoutIfNeeded()
        }
    }
}

extension UIViewController {
    var isUserInteractionEnabled: Bool {
        set {
            self.view.isUserInteractionEnabled = newValue
        }
        get {
            return self.view.isUserInteractionEnabled
        }
    }
}
