/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CareKit

class BuildInsightsOperation: NSOperation {
    
    // MARK: Properties
    
    var diabetesEvents: DailyEvents?
    var glucoseEvents: DailyEvents?
    var breakfastEvents: DailyEvents?
    var lunchEvents: DailyEvents?
    var dinnerEvents: DailyEvents?
    
    // create our glucoseAverages variable
    var glucoseAverages : [Int] = []
    
    private(set) var insights = [OCKInsightItem.emptyInsightsMessage()]
    
    // MARK: NSOperation
    
    override func main() {
        // Do nothing if the operation has been cancelled.
        guard !cancelled else { return }
        
        // Create an array of insights.
        var newInsights = [OCKInsightItem]()
        
        if let insight = createMedicationAdherenceInsight() {
            newInsights.append(insight)
        }
        
        if let insight = createBackPainInsight() {
            newInsights.append(insight)
        }
        
        // Store any new insights thate were created.
        if !newInsights.isEmpty {
            insights = newInsights
        }
    }
    
    // MARK: Convenience
    
    func createMedicationAdherenceInsight() -> OCKInsightItem? {
        // Make sure there are events to parse.
        guard let diabetesEvents = diabetesEvents else { return nil }
        
        // Determine the start date for the previous week.
        let calendar = NSCalendar.currentCalendar()
        let now = NSDate()
        
        let components = NSDateComponents()
        components.day = -7
        let startDate = calendar.weekDatesForDate(calendar.dateByAddingComponents(components, toDate: now, options: [])!).start
        
        var totalEventCount = 0
        var completedEventCount = 0
        
        for offset in 0..<7 {
            components.day = offset
            let dayDate = calendar.dateByAddingComponents(components, toDate: startDate, options: [])!
            let dayComponents = NSDateComponents(date: dayDate, calendar: calendar)
            let eventsForDay = diabetesEvents[dayComponents]
            
            totalEventCount += eventsForDay.count
            
            for event in eventsForDay {
                if event.state == .Completed {
                    completedEventCount += 1
                }
            }
        }
        
        guard totalEventCount > 0 else { return nil }
        
        // Calculate the percentage of completed events.
        let medicationAdherence = Float(completedEventCount) / Float(totalEventCount)
        
        // Create an `OCKMessageItem` describing medical adherence.
        let percentageFormatter = NSNumberFormatter()
        percentageFormatter.numberStyle = .PercentStyle
        let formattedAdherence = percentageFormatter.stringFromNumber(medicationAdherence)!

        let insight = OCKMessageItem(title: "Diabetes Management Adherence", text: "Your diabetes management adherence was \(formattedAdherence) last week.", tintColor: Colors.Pink.color, messageType: .Tip)
        
        return insight
    }
    
    func createBackPainInsight() -> OCKInsightItem? {
        // Make sure there are events to parse.
        guard let diabetesEvents = diabetesEvents, breakfastEvents = breakfastEvents, lunchEvents = lunchEvents, dinnerEvents = dinnerEvents else { return nil }
        
        // Determine the date to start pain/medication comparisons from.
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.day = -7
        
        let startDate = calendar.dateByAddingComponents(components, toDate: NSDate(), options: [])!

        // Create formatters for the data.
        let dayOfWeekFormatter = NSDateFormatter()
        dayOfWeekFormatter.dateFormat = "E"
        
        let shortDateFormatter = NSDateFormatter()
        shortDateFormatter.dateFormat = NSDateFormatter.dateFormatFromTemplate("Md", options: 0, locale: shortDateFormatter.locale)

        let percentageFormatter = NSNumberFormatter()
        percentageFormatter.numberStyle = .PercentStyle

        /*
            Loop through 7 days, collecting medication adherance and pain scores
            for each.
        */
        var diabetesValues = [Float]()
        var diabetesLabels = [String]()
        var glucoseValues = [Int]()
        var glucoseLabels = [String]()
        var axisTitles = [String]()
        var axisSubtitles = [String]()
        
        for offset in 0..<7 {
            // Determine the day to components.
            components.day = offset
            let dayDate = calendar.dateByAddingComponents(components, toDate: startDate, options: [])!
            let dayComponents = NSDateComponents(date: dayDate, calendar: calendar)
            
            // empty our average array
            glucoseAverages = []
            
            // Store the pain result for the current day.
            if let result = breakfastEvents[dayComponents].first?.result, score = Int(result.valueString) where score > 0 {

                // add our breakfastEvent to our glucose array to get our average
                glucoseAverages.append(score)
                
            }
            
            // loop through the lunchEvent
            if let result = lunchEvents[dayComponents].first?.result, score = Int(result.valueString) where score > 0 {
                // add our lunchEvent to our glucose array to get our average
                glucoseAverages.append(score)
            }
            
            // loop through the dinnerEvent
            if let result = dinnerEvents[dayComponents].first?.result, score = Int(result.valueString) where score > 0 {
                // add our lunchEvent to our glucose array to get our average
                glucoseAverages.append(score)
            }
            
            // get our average and total accordingly
            if glucoseAverages.count != 0 {
                
                let average = glucoseAverages.averageInt
                
                if average != 0 {
                    glucoseValues.append(average)
                    glucoseLabels.append(String(average))
                }
                    
            } else {
                glucoseValues.append(0)
                glucoseLabels.append(NSLocalizedString("N/A", comment: ""))
            }
        
            // Store the medication adherance value for the current day.
            let diabetesEventsForDay = diabetesEvents[dayComponents]
            if let adherence = percentageEventsCompleted(diabetesEventsForDay) where adherence > 0.0 {
                // Scale the adherance to the same 0-10 scale as pain values.
                let scaledAdeherence = adherence * 500.0
                
                diabetesValues.append(scaledAdeherence)
                diabetesLabels.append(percentageFormatter.stringFromNumber(adherence)!)
            }
            else {
                diabetesValues.append(0.0)
                diabetesLabels.append(NSLocalizedString("N/A", comment: ""))
            }
            
            axisTitles.append(dayOfWeekFormatter.stringFromDate(dayDate))
            axisSubtitles.append(shortDateFormatter.stringFromDate(dayDate))
        }

        // Create a `OCKBarSeries` for each set of data.
        let painBarSeries = OCKBarSeries(title: "Average Daily Glucose Levels", values: glucoseValues, valueLabels: glucoseLabels, tintColor: Colors.Blue.color)
        let medicationBarSeries = OCKBarSeries(title: "Diabetes Management Adherence", values: diabetesValues, valueLabels: diabetesLabels, tintColor: Colors.LightBlue.color)

        /*
            Add the series to a chart, specifing the scale to use for the chart
            rather than having CareKit scale the bars to fit.
        */
        let chart = OCKBarChart(title: "Blood Glucose Levels",
                                text: nil,
                                tintColor: Colors.Blue.color,
                                axisTitles: axisTitles,
                                axisSubtitles: axisSubtitles,
                                dataSeries: [painBarSeries, medicationBarSeries],
                                minimumScaleRangeValue: 0,
                                maximumScaleRangeValue: 500)
        
        return chart
    }
    
    /**
        For a given array of `OCKCarePlanEvent`s, returns the percentage that are
        marked as completed.
    */
    private func percentageEventsCompleted(events: [OCKCarePlanEvent]) -> Float? {
        guard !events.isEmpty else { return nil }
        
        let completedCount = events.filter({ event in
            event.state == .Completed
        }).count
     
        return Float(completedCount) / Float(events.count)
    }
}

/**
 An extension to `SequenceType` whose elements are `OCKCarePlanEvent`s. The
 extension adds a method to return the first element that matches the day
 specified by the supplied `NSDateComponents`.
 */
extension SequenceType where Generator.Element: OCKCarePlanEvent {
    
    func eventForDay(dayComponents: NSDateComponents) -> Generator.Element? {
        for event in self where
                event.date.year == dayComponents.year &&
                event.date.month == dayComponents.month &&
                event.date.day == dayComponents.day {
            return event
        }
        
        return nil
    }
}
