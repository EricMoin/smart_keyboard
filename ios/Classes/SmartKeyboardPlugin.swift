import Flutter

public class SmartKeyboardPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var displayLink: CADisplayLink?

  private var currentKeyboardHeight: CGFloat = 0
  private var targetKeyboardHeight: CGFloat = 0

  private var animationStartTime: CFTimeInterval = 0
  private var animationDuration: CFTimeInterval = 0
  private var animationFromHeight: CGFloat = 0
  private var animationToHeight: CGFloat = 0

  private var isObservingKeyboardNotifications = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SmartKeyboardPlugin()

    let methodChannel = FlutterMethodChannel(
      name: "com.smart.keyboard/method",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(
      name: "com.smart.keyboard/event",
      binaryMessenger: registrar.messenger()
    )
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getKeyboardHeight":
      result(Double(currentKeyboardHeight))
    case "showKeyboard":
      UIApplication.shared.sendAction(
        #selector(UIResponder.becomeFirstResponder),
        to: nil,
        from: nil,
        for: nil
      )
      result(nil)
    case "hideKeyboard":
      UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
      )
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    registerKeyboardObserversIfNeeded()
    emitKeyboardEvent(height: currentKeyboardHeight, isAnimating: false)
    return nil
  }

  public func onCancel(withArguments _: Any?) -> FlutterError? {
    unregisterKeyboardObservers()
    invalidateDisplayLink()
    eventSink = nil
    return nil
  }

  deinit {
    unregisterKeyboardObservers()
    invalidateDisplayLink()
  }

  private func registerKeyboardObserversIfNeeded() {
    guard !isObservingKeyboardNotifications else { return }
    isObservingKeyboardNotifications = true

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleKeyboardWillShow(_:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleKeyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleKeyboardDidShow(_:)),
      name: UIResponder.keyboardDidShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleKeyboardDidHide(_:)),
      name: UIResponder.keyboardDidHideNotification,
      object: nil
    )
  }

  private func unregisterKeyboardObservers() {
    guard isObservingKeyboardNotifications else { return }
    isObservingKeyboardNotifications = false

    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
  }

  @objc private func handleKeyboardWillShow(_ notification: Notification) {
    let userInfo = notification.userInfo
    let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
    let targetHeight = keyboardHeight(from: userInfo)

    startKeyboardAnimation(to: targetHeight, duration: duration)
  }

  private func keyboardHeight(from userInfo: [AnyHashable: Any]?) -> CGFloat {
    let frame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
    return frame?.size.height ?? 0
  }

  @objc private func handleKeyboardWillHide(_ notification: Notification) {
    let userInfo = notification.userInfo
    let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
    startKeyboardAnimation(to: 0, duration: duration)
  }

  @objc private func handleKeyboardDidShow(_: Notification) {
    currentKeyboardHeight = targetKeyboardHeight
    emitKeyboardEvent(height: currentKeyboardHeight, isAnimating: false)
  }

  @objc private func handleKeyboardDidHide(_: Notification) {
    currentKeyboardHeight = 0
    targetKeyboardHeight = 0
    emitKeyboardEvent(height: 0, isAnimating: false)
  }

  private func startKeyboardAnimation(to targetHeight: CGFloat, duration: Double) {
    targetKeyboardHeight = targetHeight
    animationStartTime = CACurrentMediaTime()
    animationDuration = max(duration, 0)
    animationFromHeight = currentKeyboardHeight
    animationToHeight = targetHeight

    invalidateDisplayLink()

    if animationDuration == 0 || animationFromHeight == animationToHeight {
      currentKeyboardHeight = animationToHeight
      emitKeyboardEvent(height: currentKeyboardHeight, isAnimating: false)
      return
    }

    let link = CADisplayLink(target: self, selector: #selector(updateKeyboardAnimation))
    displayLink = link
    link.add(to: .main, forMode: .common)
  }

  @objc private func updateKeyboardAnimation() {
    guard animationDuration > 0 else {
      currentKeyboardHeight = animationToHeight
      invalidateDisplayLink()
      emitKeyboardEvent(height: currentKeyboardHeight, isAnimating: false)
      return
    }

    let elapsed = CACurrentMediaTime() - animationStartTime
    let linearProgress = min(elapsed / animationDuration, 1.0)
    let easedProgress = 1 - pow(1 - linearProgress, 3)

    currentKeyboardHeight = animationFromHeight + (animationToHeight - animationFromHeight) * CGFloat(easedProgress)
    emitKeyboardEvent(height: currentKeyboardHeight, isAnimating: true)

    if linearProgress >= 1.0 {
      currentKeyboardHeight = animationToHeight
      invalidateDisplayLink()
    }
  }

  private func invalidateDisplayLink() {
    displayLink?.invalidate()
    displayLink = nil
  }

  private func emitKeyboardEvent(height: CGFloat, isAnimating: Bool) {
    let emitBlock = { [weak self] in
      guard let self = self, let sink = self.eventSink else { return }
      let payload: [String: Any] = [
        "height": Double(height),
        "targetHeight": Double(self.targetKeyboardHeight),
        "isAnimating": isAnimating,
        "isVisible": height > 0
      ]
      sink(payload)
    }

    if Thread.isMainThread {
      emitBlock()
    } else {
      DispatchQueue.main.async(execute: emitBlock)
    }
  }
}
