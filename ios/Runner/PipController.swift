import AVFoundation
import AVKit
import Flutter
import UIKit

final class PipController: NSObject {
  private static var shared: PipController?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "newtube/pip",
      binaryMessenger: registrar.messenger()
    )
    let controller = PipController(channel: channel)
    channel.setMethodCallHandler(controller.handle)
    shared = controller
  }

  static func startPendingIfPossible() {
    shared?.startPendingIfPossible()
  }

  static func stopActivePip() {
    shared?.stopActivePip()
  }

  private let channel: FlutterMethodChannel
  private var player: AVPlayer?
  private var pipController: AVPictureInPictureController?
  private var container: UIView?
  private var possibleObservation: NSKeyValueObservation?
  private var startPending = false
  private var pendingPosition: Double = 0
  private var pendingRate: Float = 1
  private var pendingPlaying = false
  private var preparedKey: String?
  private var wasPlaying = false
  private var lastPosition: Double = 0
  private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "enterPip":
      guard
        let args = call.arguments as? [String: Any],
        let url = (args["url"] as? String).flatMap(URL.init(string:))
      else {
        result(false)
        return
      }
      enterPip(
        url: url,
        audioUrl: (args["audioUrl"] as? String).flatMap(URL.init(string:)),
        position: args["position"] as? Double ?? 0,
        rate: Float(args["rate"] as? Double ?? 1),
        playing: args["playing"] as? Bool ?? true,
        result: result
      )
    case "preparePip":
      guard
        let args = call.arguments as? [String: Any],
        let url = (args["url"] as? String).flatMap(URL.init(string:))
      else {
        result(false)
        return
      }
      prepare(
        url: url,
        audioUrl: (args["audioUrl"] as? String).flatMap(URL.init(string:))
      )
      result(true)
    case "exitPip":
      startPending = false
      if pipController?.isPictureInPictureActive == true {
        pipController?.stopPictureInPicture()
      } else {
        teardown()
      }
      result(nil)
    case "isPipActive":
      result(pipController?.isPictureInPictureActive == true || startPending)
    case "pipPosition":
      let seconds = player?.currentTime().seconds
      result(seconds?.isFinite == true ? seconds! : lastPosition)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func enterPip(
    url: URL,
    audioUrl: URL?,
    position: Double,
    rate: Float,
    playing: Bool,
    result: @escaping FlutterResult
  ) {
    guard AVPictureInPictureController.isPictureInPictureSupported(),
          pipController != nil || hostView() != nil else {
      result(false)
      return
    }
    beginBackgroundTask()
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
    try? AVAudioSession.sharedInstance().setActive(true)
    pendingPosition = position
    pendingRate = rate
    pendingPlaying = playing
    startPending = true
    prepare(url: url, audioUrl: audioUrl)
    if let pip = pipController, player?.currentItem != nil {
      player?.seek(to: CMTime(seconds: position, preferredTimescale: 600))
      startIfPossible(pip)
    }
    result(true)
  }

  private func prepare(url: URL, audioUrl: URL?) {
    let key = "\(url.absoluteString)|\(audioUrl?.absoluteString ?? "")"
    if preparedKey == key && pipController != nil { return }
    guard let host = hostView() else { return }
    preparedKey = key
    ensurePipeline(host: host)
    let item = Self.makeItem(url: url, audioUrl: audioUrl)
    guard preparedKey == key else { return }
    player?.replaceCurrentItem(with: item)
    if startPending {
      player?.seek(to: CMTime(seconds: pendingPosition, preferredTimescale: 600))
      if let pip = pipController { startIfPossible(pip) }
    }
  }

  private func ensurePipeline(host: UIView) {
    guard pipController == nil else { return }
    let holder = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    holder.isUserInteractionEnabled = false
    holder.alpha = 0.01
    host.addSubview(holder)
    container = holder

    let layer = AVPlayerLayer()
    layer.frame = holder.bounds
    holder.layer.addSublayer(layer)

    let player = AVPlayer()
    layer.player = player
    self.player = player

    let pip = AVPictureInPictureController(playerLayer: layer)
    pip?.delegate = self
    pipController = pip
    possibleObservation = pip?.observe(\.isPictureInPicturePossible) {
      [weak self] controller, _ in
      DispatchQueue.main.async {
        self?.startIfPossible(controller)
      }
    }
  }

  private func startPendingIfPossible() {
    guard let pip = pipController else { return }
    startIfPossible(pip)
  }

  private func stopActivePip() {
    guard let pip = pipController, pip.isPictureInPictureActive else { return }
    pip.stopPictureInPicture()
  }

  private static func makeItem(url: URL, audioUrl: URL?) -> AVPlayerItem {
    guard let audioUrl else { return AVPlayerItem(url: url) }
    do {
      let videoAsset = AVURLAsset(url: url)
      let audioAsset = AVURLAsset(url: audioUrl)
      let composition = AVMutableComposition()
      if let videoTrack = videoAsset.tracks(withMediaType: .video).first,
         let track = composition.addMutableTrack(
           withMediaType: .video,
           preferredTrackID: 0
         ) {
        let duration = videoAsset.duration
        try track.insertTimeRange(
          CMTimeRange(start: CMTime.zero, duration: duration),
          of: videoTrack,
          at: CMTime.zero
        )
      }
      if let audioTrack = audioAsset.tracks(withMediaType: .audio).first,
         let track = composition.addMutableTrack(
           withMediaType: .audio,
           preferredTrackID: 0
         ) {
        let duration = audioAsset.duration
        try track.insertTimeRange(
          CMTimeRange(start: CMTime.zero, duration: duration),
          of: audioTrack,
          at: CMTime.zero
        )
      }
      return AVPlayerItem(asset: composition)
    } catch {
      return AVPlayerItem(url: url)
    }
  }

  private func startIfPossible(_ controller: AVPictureInPictureController) {
    guard startPending,
          !controller.isPictureInPictureActive,
          controller.isPictureInPicturePossible else { return }
    controller.startPictureInPicture()
  }

  private func hostView() -> UIView? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController?
      .view
  }

  private func beginBackgroundTask() {
    guard backgroundTask == .invalid else { return }
    backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
      DispatchQueue.main.async {
        self?.endBackgroundTask()
      }
    }
  }

  private func endBackgroundTask() {
    guard backgroundTask != .invalid else { return }
    UIApplication.shared.endBackgroundTask(backgroundTask)
    backgroundTask = .invalid
  }

  private func teardown() {
    possibleObservation?.invalidate()
    possibleObservation = nil
    pipController = nil
    player?.pause()
    player = nil
    container?.removeFromSuperview()
    container = nil
    preparedKey = nil
    endBackgroundTask()
  }
}

extension PipController: AVPictureInPictureControllerDelegate {
  func pictureInPictureControllerDidStartPictureInPicture(
    _ controller: AVPictureInPictureController
  ) {
    startPending = false
    if pendingPlaying {
      player?.playImmediately(atRate: pendingRate)
    }
    channel.invokeMethod("pipModeChanged", arguments: ["active": true])
    endBackgroundTask()
  }

  func pictureInPictureControllerWillStopPictureInPicture(
    _ controller: AVPictureInPictureController
  ) {
    wasPlaying = player?.timeControlStatus == .playing
    let seconds = player?.currentTime().seconds
    if let seconds, seconds.isFinite { lastPosition = seconds }
  }

  func pictureInPictureControllerDidStopPictureInPicture(
    _ controller: AVPictureInPictureController
  ) {
    channel.invokeMethod(
      "pipModeChanged",
      arguments: [
        "active": false,
        "position": lastPosition,
        "playing": wasPlaying,
      ]
    )
    teardown()
  }

  func pictureInPictureController(
    _ controller: AVPictureInPictureController,
    failedToStartPictureInPictureWithError error: Error
  ) {
    startPending = false
    channel.invokeMethod(
      "pipModeChanged",
      arguments: ["active": false, "position": pendingPosition, "playing": pendingPlaying]
    )
    teardown()
  }

  func pictureInPictureController(
    _ controller: AVPictureInPictureController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
  ) {
    completionHandler(true)
  }
}
