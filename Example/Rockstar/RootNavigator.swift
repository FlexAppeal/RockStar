//
//  ViewController.swift
//  Rockstar
//
//  Created by joannis on 06/09/2018.
//  Copyright (c) 2018 joannis. All rights reserved.
//

import UIKit
import Rockstar

final class RootNavigator: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        UIKitAppState.default.currentNavigator = self
    }
}

enum AuthenticationMechanism {
    case none
    case mongoCR
    case scramSHA1
    case scramSHA256
    case certificate
    
    var isPasswordBased: Bool {
        return self != .none && self != .certificate
    }
    
    var requiresCertificate: Bool {
        return self == .certificate
    }
}

final class ApplicationView: UIKitApplication {
    override func configure(_ application: ApplicationContext) {
        let mainView = UINavigationController()
        let favouriteDatabases = TableView<UIKitPlatform>()
        let viewHandle = mainView.setView(to: favouriteDatabases)
        viewHandle.title = "Favourites"
        
        print(viewHandle.title)
        
        viewHandle.addAction(named: "New") { navigationView in
            let builder = FormBuilder<UIKitPlatform>()
            
            let connectionString = TextField()
            builder.addRow(connectionString)
            
            let hostname = TextField()
            builder.addRow(hostname)//(validator: HostnameValidator()))

            hostname.placeholder = "example.com"

            let port = TextField()//validator: IntegerValidator())
            builder.addRow(port)
            port.text = "27017"
            port.placeholder = "27017"

            let username = TextField()
            builder.addRow(username)
//            password.placeholder = Application.translation(for: .username)

            let password = TextField.password()
            builder.addRow(password)
//            password.placeholder = Application.translation(for: .password)
            
//            let certificate = builder.addRow(FileSelector(type: .certificate))

//            let mechanism = builder.addSelection(
//                result: AuthenticationMechanism.self,
//                [
//                    "None": .none,
//                    "MongoDB CR": .mongoCR,
//                    "SCRAM-SHA-1": .scramSHA1,
//                    "SCRAM-SHA-256": .scramSHA256,
//                    "X509": .certificate
//                ]
//            )
//
//            builder.withRow(snappedTo: .bottom, offset: .bottom(24.pixels)) { row in
//                let cancel = row.add(FormButton(), alignedTo: .left)
//                let submit = row.add(FormButton(), alignedTo: .right)
//
//                cancel.onClick {
//                    navigationView.return(to: favouriteDatabases)
//                }
//
//                submit.onClick {
//                    let settings = try ConnectionSettings(...)
//
//                    connectionStore.append(settings)
//                    navigationView.return(to: favouriteDatabases)
//                }
//            }
//
//            mechanism.beforeChange { new in
//                password.hidden = !new.isPasswordBased
//                certificate.hidden = !new.requiresCertificate
//            }
            
            connectionString.beforeChange { new in
                print(new)
//                do {
//                    let settings = try ConnectionSettings(parsedFrom: new)
//                    hostname.text = settings.hostname
//                    port.text = settings.port
//                    username.text = settings.username ?? ""
//                    password.text = settings.password
//                    certificate.file = nil
//                } catch {}
            }
            
            navigationView.open(builder.makeFormController())
        }
        
        application.display(mainView)
    }
}
