//
//  ViewController.swift
//  CryptoViewer
//
//  Created by Rick Pearce on 4/25/18.
//  Copyright © 2018 Rick Pearce. All rights reserved.
//

import UIKit
import CommonCrypto
import Alamofire

class ViewController: UIViewController {

    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var balanceLbl: UILabel!
    @IBOutlet weak var valueLbl: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    let API_KEY = "rvUsT0eEztzKWTnoIg4yvN6JpgitZDw2"
    let SECRET = "xkChN8W9yDAMIph6ES4Jk1GctWz4W5Rq"
    let USER_ID = "ajvf0578"
    let CURRENT_BALANCE_URL = "https://www.bitstamp.net/api/v2/balance/"
    let CURRENT_PRICE_URL = "https://www.bitstamp.net/api/v2/ticker/xrpusd/"
    
    var currentPrice: Double = 0
    var balance: Double = 0
    var balances: [Double] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchCurrentPrice()
        
        
    }

    func fetchCurrentPrice() {
        spinner.isHidden = false
        spinner.startAnimating()
        Alamofire.request(CURRENT_PRICE_URL).responseJSON { (response) in
            if response.result.error == nil {
                if let json: Data = response.data {
                    let decoder = JSONDecoder()
                    let result = try! decoder.decode(XRPPrice.self, from: json)
                    self.currentPrice = Double(result.last)!
                    self.fetchCurrentBalance()
                }
            } else {
                print("Error getting data: \(String(describing: response.error?.localizedDescription))")
            }
        }
    }
    
    func fetchCurrentBalance() {
        let nonce = Int(NSDate().timeIntervalSince1970)
        let message = "\(nonce)\(USER_ID)\(API_KEY)"
        let signature = message.hmac(key: SECRET).uppercased()
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        let paramaters : Parameters = ["key" : API_KEY, "signature" : signature, "nonce" : nonce]
        //print(nonce)
        //print(signature.uppercased())
        Alamofire.request(CURRENT_BALANCE_URL, method: .post, parameters: paramaters, encoding: URLEncoding.default, headers: headers).responseJSON { (response) in
            if response.result.error == nil {
                //print(response.result.value.debugDescription)
                if let jsonResponse: Data = response.data {
                    let decoder = JSONDecoder()
                    let result = try! decoder.decode(BitStampAccount.self, from: jsonResponse)
                    self.balance += Double(result.xrp_balance)!
                    self.fetchToastWalletData()
                }
            } else {
                print("Error retrieving data: \(String(describing: response.result.error?.localizedDescription))")
            }
            self.spinner.stopAnimating()
            self.spinner.isHidden = true
        }
    }
    
    func fetchToastWalletData() {
        Alamofire.request("https://data.ripple.com/v2/accounts/rNwwnwdG9Sum9vRMfREWMUjtSDxXCgM59H/balances").responseJSON { (response) in
            if response.result.error == nil {
                if let jsonResponse : Data = response.data {
                    let decoder = JSONDecoder()
                    let result = try! decoder.decode(Account.self, from: jsonResponse)
                    let currentBalance = Double(result.balances[0].value)
                    self.balance += currentBalance!
                }
            }
            self.updateValues()
        }
    }
    
    func updateValues() {
        self.priceLbl.text = String(format: "%.02f",self.currentPrice)
        self.balanceLbl.text = String(format: "%.02f",self.balance)
        self.valueLbl.text = String(format: "%.02f", (self.balance * self.currentPrice))
    }

    @IBAction func refreshBtnPressed(_ sender: Any) {
        balance = 0
        priceLbl.text = "updating"
        balanceLbl.text = "updating"
        valueLbl.text = "updating"
        fetchCurrentPrice()
    }
    
}

extension String {
    
    func hmac(key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), key, key.count, self, self.count, &digest)
        let data = Data(bytes: digest)
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
    
}

struct Balance: Codable {
    let currency: String
    let value: String
}

struct Account: Codable {
    let result: String
    let ledger_index: Int
    let limit: Int
    let balances: [Balance]
}

struct BitStampAccount: Codable {
    let xrp_balance: String
}

struct XRPPrice: Codable {
    let last: String
}
