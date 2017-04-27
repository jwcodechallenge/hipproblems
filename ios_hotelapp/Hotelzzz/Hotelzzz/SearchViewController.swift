//
//  SearchViewController.swift
//  Hotelzzz
//
//  Created by Steve Johnson on 3/22/17.
//  Copyright © 2017 Hipmunk, Inc. All rights reserved.
//

import Foundation
import WebKit
import UIKit


private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "YYYY-mm-dd"
    return formatter
}()

private func jsonStringify(_ obj: [AnyHashable: Any]) -> String {
    let data = try! JSONSerialization.data(withJSONObject: obj, options: [])
    return String(data: data, encoding: .utf8)!
}


enum ListingSort: String {
    case Name = "name"
    case PriceAscending = "priceAscend"
    case PriceDescending = "priceDescend"
    case none
    
    var displayTitle: String {
        switch self {
        case .Name: return "Name"
        case .PriceAscending: return "Price Ascending"
        case .PriceDescending: return "Price Descending"
        case .none: return ""
        }
    }
    
    init(with displayTitle: String) {
        switch displayTitle {
        case ListingSort.Name.displayTitle: self = ListingSort.Name
        case ListingSort.PriceAscending.displayTitle: self = ListingSort.PriceAscending
        case ListingSort.PriceDescending.displayTitle: self = ListingSort.PriceDescending
        default: self = ListingSort.none
        }
    }
}

class SearchViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    struct Search {
        let location: String
        let dateStart: Date
        let dateEnd: Date

        var asJSONString: String {
            return jsonStringify([
                "location": location,
                "dateStart": dateFormatter.string(from: dateStart),
                "dateEnd": dateFormatter.string(from: dateEnd)
            ])
        }
    }

    private var _searchToRun: Search?
    private var selectedHotel = [AnyHashable:Any]()
    private var selectedSort: ListingSort = .none {
        didSet {
            webView.evaluateJavaScript(
                "window.JSAPI.setHotelSort(\"\(selectedSort.rawValue)\")",
                completionHandler: nil)
        }
    }
    private var priceRange = (0, 0) {
        didSet {
            let lower = priceRange.0 == 0 ? "null" : String(priceRange.0)
            let upper = priceRange.1 == 0 ? "null" : String(priceRange.1)
            let js = "window.JSAPI.setHotelFilters({priceMin: \(lower), priceMax: \(upper)})"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: CGRect.zero, configuration: {
            let config = WKWebViewConfiguration()
            config.userContentController = {
                let userContentController = WKUserContentController()

                // DECLARE YOUR MESSAGE HANDLERS HERE
                userContentController.add(self, name: "API_READY")
                userContentController.add(self, name: "HOTEL_API_HOTEL_SELECTED")
                userContentController.add(self, name: "HOTEL_API_RESULTS_READY")

                return userContentController
            }()
            return config
        }())
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self

        self.view.addSubview(webView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[webView]|", options: [], metrics: nil, views: ["webView": webView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[webView]|", options: [], metrics: nil, views: ["webView": webView]))
        return webView
    }()

    func search(location: String, dateStart: Date, dateEnd: Date) {
        _searchToRun = Search(location: location, dateStart: dateStart, dateEnd: dateEnd)
        self.webView.load(URLRequest(url: URL(string: "http://hipmunk.github.io/hipproblems/ios_hotelapp/")!))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let alertController = UIAlertController(title: NSLocalizedString("Could not load page", comment: ""), message: NSLocalizedString("Looks like the server isn't running.", comment: ""), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Bummer", comment: ""), style: .default, handler: nil))
        self.navigationController?.present(alertController, animated: true, completion: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "API_READY":
            guard let searchToRun = _searchToRun else { fatalError("Tried to load the page without having a search to run") }
            self.webView.evaluateJavaScript(
                "window.JSAPI.runHotelSearch(\(searchToRun.asJSONString))",
                completionHandler: nil)
        case "HOTEL_API_HOTEL_SELECTED":
            self.selectedHotel = (message.body as! [AnyHashable:Any])
            self.performSegue(withIdentifier: "hotel_details", sender: nil)
        case "HOTEL_API_RESULTS_READY":
            let results = ((message.body as! [AnyHashable:Any])["results"] as! [Any])
            self.title = "\(results.count) Results"
        default: break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let detailVC = segue.destination as? UINavigationController, let hotelVC = detailVC.topViewController as? HotelViewController  {
            hotelVC.configure(with: self.selectedHotel)
        }
    }
    
    @IBAction func showSort(_ sender: Any) {
        let alert = UIAlertController(title: "Sort results by:", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
        
        let actionHandler: (UIAlertAction) -> Void = { action in
            self.selectedSort = ListingSort(with: action.title!)
        }
        ["Name", "Price Ascending", "Price Descending"].forEach { (sortTitle) in
            let action = UIAlertAction(title: sortTitle, style: .default, handler: actionHandler)
            action.setValue(sortTitle == self.selectedSort.displayTitle, forKey: "checked")
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if self.presentedViewController != nil {
            self.presentedViewController?.dismiss(sender: self)
        }
        self.present(alert, animated: true)
    }
    
    @IBAction func showFilter(_ sender: Any) {
        let alert = UIAlertController(title: "Filter by price:\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
        
        let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 300, height: 150))
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.dataSource = self
        picker.delegate = self
        
        let doneButton = UIButton(type: UIButtonType.system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        doneButton.addTarget(alert, action: #selector(dismiss(sender:)), for: .touchUpInside)
        
        alert.view.addSubview(picker)
        alert.view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([picker.leftAnchor.constraint(equalTo: alert.view.leftAnchor),
                                     picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 20),
                                     picker.rightAnchor.constraint(equalTo: alert.view.rightAnchor),
                                     picker.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: 20),
                                     doneButton.rightAnchor.constraint(equalTo: alert.view.rightAnchor, constant: -15),
                                     doneButton.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 8)])
        
        if self.presentedViewController != nil {
            self.presentedViewController?.dismiss(sender: self)
        }
        
        self.present(alert, animated: true) {
            /* UIKit doesn't offer completion blocks on its datasource-driven views,
            so we take advantage of CATransaction for a similar effect */
            
            CATransaction.begin()
            picker.reloadAllComponents()
            CATransaction.setCompletionBlock({ 
                picker.selectRow((self.priceRange.0/100)+1, inComponent: 0, animated: false)
                picker.selectRow((self.priceRange.1/100)+1, inComponent: 1, animated: false)
            })
            CATransaction.commit()
        }
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 11
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "$\(max(0, row - 1)*100)"
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if row == 0 {
            return NSAttributedString(string: component == 0 ? "Min" : "Max",
                                      attributes: [NSForegroundColorAttributeName : UIColor.darkGray])
        }
        
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var adjustedRow = row
        
        if row == 0 {
            pickerView.selectRow(1, inComponent: component, animated: true)
            adjustedRow += 1
        }
        
        switch component {
        case 0: self.priceRange.0 = max(0, adjustedRow - 1)*100
        case 1: self.priceRange.1 = max(0, adjustedRow - 1)*100
        default: break
        }
    }
}
