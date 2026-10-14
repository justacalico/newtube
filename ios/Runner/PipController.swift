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

  private let channel: FlutterMethodChannel
  private var player: AVPlayer?
  private var pipController: AVPictureInPictureController?
  private var container: UIView?
  private var possibleObservation: NSKeyValueObservation?
  private var startPending = false
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
          let host = hostView() else {
      result(false)
      return
    }
    beginBackgroundTask()
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
    try? AVAudioSession.sharedInstance().setActive(true)
    Task { @MainActor in
      let item = await Self.makeItem(url: url, audioUrl: audioUrl)
      self.attach(item, to: host, position: position, rate: rate, playing: playing)
      result(true)
    }
  }

  private static func makeItem(url: URL, audioUrl: URL?) async -> AVPlayerItem {
    guard let audioUrl else { return AVPlayerItem(url: url) }
    do {
      let videoAsset = AVURLAsset(url: url)
      let audioAsset = AVURLAsset(url: audioUrl)
      let composition = AVMutableComposition()
      if let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
         let track = composition.addMutableTrack(
           withMediaType: .video,
           preferredTrackID: kCMPersistentTrackId_Invalid
         ) {
        let duration = try await videoAsset.load(.duration)
        try track.insertTimeRange(
          CMTimeRange(start: .zero, duration: duration),
          of: videoTrack,
          at: .zero
        )
      }
      if let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first,
         let track = composition.addMutableTrack(
           withMediaType: .audio,
           preferredTrackID: kCMPersistentTrackId_Invalid
         ) {
        let duration = try await audioAsset.load(.duration)
        try track.insertTimeRange(
          CMTimeRange(start: .zero, duration: duration),
          of: audioTrack,
          at: .zero
        )
      }
      return AVPlayerItem(asset: composition)
    } catch {
      return AVPlayerItem(url: url)
    }
  }

  @MainActor
  private func attach(
    _ item: AVPlayerItem,
    to host: UIView,
    position: Double,
    rate: Float,
    playing: Bool
  ) {
    if pipController == nil {
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
        self?.startIfPossible(controller)
      }
    }
    player?.replaceCurrentItem(with: item)
    player?.seek(to: CMTime(seconds: position, preferredTimescale: 600))
    if playing {
      player?.playImmediately(atRate: rate)
    }
    guard let pip = pipController, !pip.isPictureInPictureActive else {
      startPending = false
      return
    }
    startPending = true
    startIfPossible(pip)
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
      self?.endBackgroundTask()
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
    endBackgroundTask()
  }
}

extension PipController: AVPictureInPictureControllerDelegate {
  func pictureInPictureControllerDidStartPictureInPicture(
    _ controller: AVPictureInPictureController
  ) {
    startPending = false
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
    teardown()
  }

  func pictureInPictureController(
    _ controller: AVPictureInPictureController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
  ) {
    completionHandler(true)
  }
}
