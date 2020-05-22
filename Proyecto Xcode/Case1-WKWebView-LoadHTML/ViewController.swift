//
//  ViewController.swift
//  Case1-WKWebView-LoadHTML
//
//  Created by Belén on 10/05/2020.
//  Copyright © 2020 IWEB. All rights reserved.
//

import UIKit
import WebKit

let MessageHandler = "didFetchValue"

class ViewController: UIViewController {
    
    var webView: WKWebView!
    var valueKey: String!
    var needRequest: Bool!
    var lastMessage: String!
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var lessButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: MessageHandler)
        config.userContentController = contentController
        self.webView = WKWebView(frame: CGRect.init(), configuration: config)
        
        //self.webView.load(URLRequest(url: URL(string: "http://pruebaswifthtml.herokuapp.com")!))
        self.webView.load(URLRequest(url: URL(string: "http://127.0.0.1:3000")!))
        print("¿Cargando app.js?")
        print(self.webView.isLoading ? "Sí. Hay que esperar" : "Ya he terminado!")
        while (self.webView.isLoading) {
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.1, false)
        }
        print(self.webView.isLoading ? "Sí. Hay que esperar" : "Ya he terminado!")
        self.valueKey = ""
        self.lastMessage = ""
        self.needRequest = true
        
        self.webView.evaluateJavaScript("setup()") { result, _ in
            print(result!)
            print("")
        }
    }
    
    @IBAction func incr(_ sender: Any) {
        self.webView.evaluateJavaScript("incr()") { result, _ in
            print("-----------------")
            print(result as! String)
            self.lastMessage = result as? String
        }
    }
    
    @IBAction func decr(_ sender: Any) {
        self.webView.evaluateJavaScript("decr()") { result, error in
            if (error == nil) {
                print("-----------------")
                print(result as! String)
                self.lastMessage = result as? String
            } else {
                print(error ?? "Error desconocido")
            }
        }
    }
    
    @IBAction func reset(_ sender: Any) {
        self.webView.evaluateJavaScript("reset()") { result, error in
            if (error == nil) {
                print("-----------------")
                print(result as! String)
                self.lastMessage = result as? String
            } else {
                print(error ?? "Error desconocido")
            }
        }
    }
}


extension ViewController: WKScriptMessageHandler, WKNavigationDelegate {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        let body = message.body as! String
        
        if (body.localizedStandardContains("Estado actualizado") && self.needRequest){
            // Tengo que hacer cacheCall()
            self.lastMessage = body
            self.needRequest = false
            self.webView.evaluateJavaScript("getKey()") { result, _ in
                // Mensaje recibido: La clave es _
                // Si no tenia la clave la guardo y la imprimo. Sino, ignoro el mensaje.
                if (self.lastMessage != "Estado actualizado") {
                    // Es la primera actualizacion
                    print(body)
                    self.lastMessage = "Estado actualizado"
                }// Si no es una doble actualizacion. No imprimo para evitar duplicados
                if (!self.valueKey.hasPrefix("0x")){
                    print(result as! String)
                    self.valueKey = "\(String(describing: (result as! String).split(separator: " ").last!))"
                    self.lastMessage = result as? String
                }
            }
        } else if (body.localizedStandardContains("Estado actualizado")) { //needRequest=false
            if (self.lastMessage != "Estado actualizado") {
                // Es la primera actualizacion
                print(body)
            }// Si no es una doble actualizacion. No imprimo para evitar duplicados
            self.lastMessage = body
            let key: String! = self.valueKey
            self.webView.evaluateJavaScript("getValue(\"\(key!)\")") { result, _ in
                // Mensaje recibido: El valor es _
                if (result != nil) {
                    let valor = String(describing: (result as! String).split(separator: " ").last!)
                    if (self.label.text! != valor) {
                        // Me ha llegado un valor distinto
                        print(result as! String)
                        self.label.text = valor
                        self.needRequest = true
                        self.lastMessage = result as? String
                    }
                }
            }
        } else {
            print("Mensaje desconocido: "+body)
            self.lastMessage = body
        }
    }
}
