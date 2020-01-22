//: See and learn how the CAAnimation and CAMediaTiming properties affect rendering using dynamic Xcode playground.

import AppKit
import QuartzCore
import PlaygroundSupport

let BEGIN_TIME: CFTimeInterval = 1.0 // cannot be 0: Core Animation replaces 0 with the current parent time
let DURATION: CFTimeInterval = 8.0
let END_TIME = BEGIN_TIME + DURATION
let STEP_DURATION: CFTimeInterval = 0.1

let VIEW_WIDTH: CGFloat = 800
let VIEW_HEIGHT: CGFloat = 400
let VALUE_VIEW_WIDTH = CGFloat(DURATION / STEP_DURATION)
let LONG_TICK_WIDTH: CGFloat = 3.0
let SHORT_TICK_WIDTH: CGFloat = 1.0
let LONG_TICK_HEIGHT: CGFloat = 10.0
let SHORT_TICK_HEIGHT: CGFloat = 5.0

let DEFAULT_BEGIN_TIME = BEGIN_TIME + 2.0
let DEFAULT_DURATION: CFTimeInterval = 2.0 // 0 means "inherit from CATransaction"
let DEFAULT_TIME_OFFSET: CFTimeInterval = 0.0
let DEFAULT_REPEAT_DURATION: CFTimeInterval = 0.0 // 0 means "ignore"
let DEFAULT_FILL_MODE = CAMediaTimingFillMode.removed
let DEFAULT_SPEED: Float = 1.0
let DEFAULT_AUTOREVERSES = false


class Controller: NSObject {
    var animation: CAAnimation {
        didSet {
            updateAppearance(nil)
        }
    }

    var mainView: NSBox!
    var contentView: NSView!
    var valueViews: [NSView]!

    var beginTimeControl: NSSlider!
    var durationControl: NSSlider!
    var timeOffsetControl: NSSlider!
    var repeatDurationControl: NSSlider!
    var fillModeControl: NSPopUpButton!
    var speedValueLabel: NSTextField!
    var speedControl: NSStepper!
    var autoreversesControl: NSButton!

    init(animation: CAAnimation) {
        self.animation = animation.copy() as! CAAnimation
    }

    ///: Update animation rendering using values from the controls
    @objc func updateAppearance(_ sender: Any?) {
        speedValueLabel.floatValue = speedControl.floatValue

        let a = animation.copy() as! CAAnimation
        a.beginTime = BEGIN_TIME + beginTimeControl.doubleValue
        a.duration = durationControl.doubleValue
        a.timeOffset = timeOffsetControl.doubleValue
        a.repeatDuration = repeatDurationControl.doubleValue
        a.fillMode = CAMediaTimingFillMode(rawValue: fillModeControl.selectedItem!.title)
        a.speed = speedControl.floatValue
        a.autoreverses = autoreversesControl.state == .on

        valueViews.forEach { v in
            v.layer!.add(a, forKey: "customAnimation")
        }
    }

    func loadView() {
        mainView = NSBox(frame: NSRect(x: 0, y: 0, width: VIEW_WIDTH, height: VIEW_HEIGHT))
        mainView.borderType = .noBorder
        mainView.boxType = .custom
        mainView.cornerRadius = 0
        mainView.borderWidth = 0
        mainView.titlePosition = .noTitle
        mainView.contentViewMargins = NSSize(width: 0, height: 0)
        mainView.wantsLayer = true
        mainView.userInterfaceLayoutDirection = .leftToRight

        contentView = mainView.contentView!

        setupProgressView()
        setupControls()

        updateAppearance(nil)
    }

    func setupProgressView() {
        valueViews = stride(from: 0.0, to: DURATION, by: STEP_DURATION).map { value -> NSView in
            let v = NSView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.wantsLayer = true

            let layer = v.layer!
            layer.speed = 0
            layer.timeOffset = BEGIN_TIME + value + STEP_DURATION / 2.0 // value in the middle of the step interval
            return v
        }

        let valueProgressView = NSStackView(views: valueViews)
        valueProgressView.translatesAutoresizingMaskIntoConstraints = false
        valueProgressView.wantsLayer = true
        valueProgressView.orientation = .horizontal
        valueProgressView.spacing = 0
        valueProgressView.distribution = .fillEqually

        contentView.addSubview(valueProgressView)

        NSLayoutConstraint.activate([
            valueProgressView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10),
            valueProgressView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            valueProgressView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10),
            valueProgressView.heightAnchor.constraint(equalToConstant: 100)
        ])

        stride(from: 0, through: DURATION, by: STEP_DURATION).forEach { value in
            let tick = NSBox()
            tick.translatesAutoresizingMaskIntoConstraints = false
            tick.borderType = .noBorder
            tick.boxType = .custom
            contentView.addSubview(tick)

            let tickIndex = Int((value / STEP_DURATION).rounded())

            if tickIndex % 10 == 0 {
                // Long ticks
                tick.fillColor = NSColor.labelColor

                let label = NSTextField(labelWithString: "\(value.rounded())")
                label.translatesAutoresizingMaskIntoConstraints = false
                label.alignment = .center
                label.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
                contentView.addSubview(label)

                if tickIndex == 0 {
                    tick.centerXAnchor.constraint(equalTo: valueProgressView.leftAnchor).isActive = true
                }
                else if tickIndex == valueViews.count {
                    tick.centerXAnchor.constraint(equalTo: valueProgressView.rightAnchor).isActive = true
                }
                else {
                    tick.centerXAnchor.constraint(equalTo: valueProgressView.views[tickIndex].leftAnchor).isActive = true
                }

                NSLayoutConstraint.activate([
                    tick.topAnchor.constraint(equalTo: valueProgressView.bottomAnchor),
                    tick.widthAnchor.constraint(equalToConstant: LONG_TICK_WIDTH),
                    tick.heightAnchor.constraint(equalToConstant: LONG_TICK_HEIGHT),
                    label.topAnchor.constraint(equalTo: tick.bottomAnchor),
                    label.centerXAnchor.constraint(equalTo: tick.centerXAnchor)
                ])

            }
            else {
                // Short ticks
                tick.fillColor = NSColor.secondaryLabelColor

                NSLayoutConstraint.activate([
                    tick.topAnchor.constraint(equalTo: valueProgressView.bottomAnchor),
                    tick.centerXAnchor.constraint(equalTo: valueProgressView.views[tickIndex].leftAnchor),
                    tick.widthAnchor.constraint(equalToConstant: SHORT_TICK_WIDTH),
                    tick.heightAnchor.constraint(equalToConstant: SHORT_TICK_HEIGHT)
                ])
            }
        }
    }

    func setupControls() {
        // beginTime
        let beginTimeLabel = NSTextField(labelWithString: "beginTime:")
        beginTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        beginTimeLabel.alignment = .right

        beginTimeControl = NSSlider(value: DEFAULT_BEGIN_TIME - BEGIN_TIME, minValue: 0.0, maxValue: DURATION,
                                    target: self, action: #selector(self.updateAppearance(_:)))
        beginTimeControl.translatesAutoresizingMaskIntoConstraints = false
        beginTimeControl.sliderType = .linear
        beginTimeControl.allowsTickMarkValuesOnly = true
        beginTimeControl.numberOfTickMarks = Int((DURATION / STEP_DURATION).rounded()) + 1

        // duration
        let durationLabel = NSTextField(labelWithString: "duration:")
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.alignment = .right

        durationControl = NSSlider(value: DEFAULT_DURATION, minValue: 0.0, maxValue: DURATION,
                                   target: self, action: #selector(self.updateAppearance(_:)))
        durationControl.translatesAutoresizingMaskIntoConstraints = false
        durationControl.sliderType = .linear
        durationControl.allowsTickMarkValuesOnly = true
        durationControl.numberOfTickMarks = Int((DURATION / STEP_DURATION).rounded()) + 1

        // timeOffset
        let timeOffsetLabel = NSTextField(labelWithString: "timeOffset:")
        timeOffsetLabel.translatesAutoresizingMaskIntoConstraints = false
        timeOffsetLabel.alignment = .right

        timeOffsetControl = NSSlider(value: DEFAULT_TIME_OFFSET, minValue: -DURATION / 2, maxValue: DURATION / 2,
                                     target: self, action: #selector(self.updateAppearance(_:)))
        timeOffsetControl.translatesAutoresizingMaskIntoConstraints = false
        timeOffsetControl.sliderType = .linear
        timeOffsetControl.allowsTickMarkValuesOnly = true
        timeOffsetControl.numberOfTickMarks = Int((DURATION / STEP_DURATION).rounded()) + 1

        // repeatDuration
        let repeatDurationLabel = NSTextField(labelWithString: "repeatDuration:")
        repeatDurationLabel.translatesAutoresizingMaskIntoConstraints = false
        repeatDurationLabel.alignment = .right

        repeatDurationControl = NSSlider(value: DEFAULT_REPEAT_DURATION, minValue: 0.0, maxValue: DURATION,
                                         target: self, action: #selector(self.updateAppearance(_:)))
        repeatDurationControl.translatesAutoresizingMaskIntoConstraints = false
        repeatDurationControl.sliderType = .linear
        repeatDurationControl.allowsTickMarkValuesOnly = true
        repeatDurationControl.numberOfTickMarks = Int((DURATION / STEP_DURATION).rounded()) + 1

        // fillMode
        let fillModeLabel = NSTextField(labelWithString: "fillMode:")
        fillModeLabel.translatesAutoresizingMaskIntoConstraints = false
        fillModeLabel.alignment = .right

        fillModeControl = NSPopUpButton()
        fillModeControl.addItems(withTitles: [
            CAMediaTimingFillMode.removed.rawValue,
            CAMediaTimingFillMode.backwards.rawValue,
            CAMediaTimingFillMode.forwards.rawValue,
            CAMediaTimingFillMode.both.rawValue
        ])
        fillModeControl.selectItem(withTitle: DEFAULT_FILL_MODE.rawValue)
        fillModeControl.target = self
        fillModeControl.action = #selector(self.updateAppearance(_:))

        // speed
        let speedLabel = NSTextField(labelWithString: "speed:")
        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        speedLabel.alignment = .right

        speedValueLabel = NSTextField()
        speedValueLabel.translatesAutoresizingMaskIntoConstraints = false
        speedValueLabel.alignment = .right
        speedValueLabel.isEditable = false
        speedValueLabel.isEnabled = false

        speedControl = NSStepper()
        speedControl.minValue = -2.0
        speedControl.maxValue = 2.0
        speedControl.floatValue = DEFAULT_SPEED
        speedControl.increment = 1.0
        speedControl.autorepeat = false
        speedControl.target = self
        speedControl.action = #selector(self.updateAppearance(_:))

        let speedValueGroup = NSStackView(views: [speedValueLabel, speedControl])
        speedValueGroup.translatesAutoresizingMaskIntoConstraints = false
        speedValueGroup.spacing = 2

        // autoreverses
        autoreversesControl = NSButton(checkboxWithTitle: "autoreverses",
                                       target: self, action: #selector(self.updateAppearance(_:)))
        autoreversesControl.state = DEFAULT_AUTOREVERSES ? .on : .off

        // Layout
        let controlsView = NSGridView(views: [
            [beginTimeLabel, beginTimeControl],
            [durationLabel, durationControl],
            [timeOffsetLabel, timeOffsetControl],
            [repeatDurationLabel, repeatDurationControl],
            [fillModeLabel, fillModeControl],
            [speedLabel, speedValueGroup],
            [NSGridCell.emptyContentView, autoreversesControl]
        ])
        controlsView.translatesAutoresizingMaskIntoConstraints = false
        controlsView.yPlacement = .none
        controlsView.rowAlignment = .none
        controlsView.column(at: 0).xPlacement = .trailing
        controlsView.column(at: 1).xPlacement = .leading
        controlsView.column(at: 1).width = 350

        contentView.addSubview(controlsView)
        NSLayoutConstraint.activate([
            controlsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            controlsView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            beginTimeLabel.centerYAnchor.constraint(equalTo: beginTimeControl.firstBaselineAnchor, constant: -3),

            durationLabel.centerYAnchor.constraint(equalTo: durationControl.firstBaselineAnchor, constant: -3),

            timeOffsetLabel.centerYAnchor.constraint(equalTo: timeOffsetControl.firstBaselineAnchor, constant: -3),
            repeatDurationLabel.centerYAnchor.constraint(equalTo: repeatDurationControl.firstBaselineAnchor, constant: -3),
            fillModeLabel.firstBaselineAnchor.constraint(equalTo: fillModeControl.firstBaselineAnchor),
            speedValueLabel.widthAnchor.constraint(equalToConstant: 30),
            speedLabel.firstBaselineAnchor.constraint(equalTo: speedValueLabel.firstBaselineAnchor)
        ])
    }
}

let a = CABasicAnimation(keyPath: "backgroundColor")
a.fromValue = #colorLiteral(red: 0.9647058824, green: 0.7333333333, blue: 0.2549019608, alpha: 1).cgColor
a.toValue = #colorLiteral(red: 0.3764705882, green: 0.6431372549, blue: 0.8705882353, alpha: 1).cgColor
a.timingFunction = CAMediaTimingFunction(name: .linear)

let controller = Controller(animation: a)
controller.loadView()

PlaygroundPage.current.liveView = controller.mainView
