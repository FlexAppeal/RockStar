import Rockstar
import UIKit

let app = UIKitApplication()

let chatController = PostsController()

// On application boot
app.willFinishLaunching.always {
    app.setRootView(to: chatController)
}

app.start()
