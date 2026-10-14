import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func sceneDidEnterBackground(_ scene: UIScene) {
    super.sceneDidEnterBackground(scene)
    PipController.startPendingIfPossible()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    PipController.stopActivePip()
  }
}
