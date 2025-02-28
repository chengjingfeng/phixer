//
//  ColorSchemeViewController.swift
//  phixer
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import Neon
import AVFoundation
import MediaPlayer
import AudioToolbox

import GoogleMobileAds
//import Kingfisher




// delegate method to let the launching ViewController know that this one has finished
protocol ColorSchemeViewControllerDelegate: class {
    // returns the chosen scheme. List will be empty if nothing is chosen
    func colorSchemeCompleted(scheme:[UIColor])
}



// This is the View Controller for developing a color scheme

class ColorSchemeViewController: CoordinatedController {
    
    // delegate for handling events
    weak var delegate: ColorSchemeViewControllerDelegate?
    


    
    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    var defaultColor:UIColor = UIColor.flatMint
    let defaultCount:Int = 6
    
    lazy var selectedColor:UIColor = defaultColor
    lazy var selectedCount:Int = defaultCount
    var selectedColorScheme:ColorUtilities.ColorSchemeType = .triadic
    
    var colorSchemeList:[String] = []
    
    
    // Main Views
    var adView: GADBannerView! = GADBannerView()
    var parameterView: UIView! = UIView()
    var colorSchemeView: ColorSchemeView! = ColorSchemeView()
    var controlView:UIView! = UIView()
    let seedButton = SquareButton(bsize:48.0)
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Color Scheme"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "default"
    }
    
    /////////////////////////////
    // MARK: - Boilerplate
    /////////////////////////////

    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Logging nicety, show that controller has changed:
        print ("\n========== \(String(describing: type(of: self))) ==========")

        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        self.defaultColor = theme.buttonColor

        doInit()
        doLayout()
        
        // start Ads
        if (UISettings.showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
        self.updateColors()

    }
    

    
    
    /////////////////////////////
    // MARK: - Initialisation
    /////////////////////////////

    static var initDone:Bool = false

    
    func doInit(){
        
        if (!ColorSchemeViewController.initDone){
            ColorSchemeViewController.initDone = true
            
            selectedColor = defaultColor
            selectedCount = defaultCount
        }
    }
    
    
    func doLayout(){
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        
        //UISettings.showAds = (UISettings.isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        //UISettings.showAds = false // debug
        
        
        view.backgroundColor = theme.backgroundColor // default seems to be white
        
       
        //top-to-bottom layout scheme
        // Note: need to define and add subviews before modifying constraints
        
        // Ads
        if (UISettings.showAds){
            adView.frame.size.height = UISettings.panelHeight
            adView.frame.size.width = displayWidth
        }

        if (UISettings.showAds){
            adView.isHidden = false
            view.addSubview(adView)
        } else {
            log.debug("Not showing Ads in landscape mode")
            adView.isHidden = true
        }
        
        // Input Parameters
        layoutParameters()
        view.addSubview(parameterView)
        
        // Generated Color Scheme
        layoutColorScheme()
        view.addSubview(colorSchemeView)
        
        // Controls
        layoutControls()
        view.addSubview(controlView)
        
        // layout constraints
    
        if (UISettings.showAds){
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: adView.frame.size.height)
            parameterView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: parameterView.frame.size.height)
        } else {
            parameterView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: parameterView.frame.size.height)
        }
        
        controlView.anchorAndFillEdge(.bottom, xPad: 0, yPad: UISettings.topBarHeight, otherSize: UISettings.panelHeight)
        colorSchemeView.alignBetweenVertical(align: .underCentered, primaryView: parameterView, secondaryView: controlView, padding: 1.0, width: displayWidth)
    }
    
   
    
    /////////////////////////////
    // MARK: - Layout Functions
    /////////////////////////////
    
    
    func layoutParameters(){
        
        parameterView.frame.size.height = UISettings.panelHeight * 3.0
        parameterView.frame.size.width = displayWidth

        // Seed Color
        let seedLabel = UILabel()
        
        
        // Number of colours to generate
        let numLabel = UILabel()
        let numEntry = UITextField()
        
        
        // Colour Scheme selection
        let schemeLabel = UILabel()
        let schemeSelector:UIPickerView = UIPickerView()

        
        // set the label widths to 1/2 the display width and right justify the text
        for label in [seedLabel, numLabel, schemeLabel] {
            label.frame.size.width = (displayWidth / 2) - 32
            label.frame.size.height = UISettings.panelHeight
            label.textAlignment = .right
            label.textColor = theme.textColor
        }
        
        // set up parameters
        seedLabel.text = "Seed Color :  "
        seedButton.setColor(selectedColor)
        seedButton.addTarget(self, action: #selector(self.seedColorDidPress), for: .touchUpInside)

        numLabel.text = "Number of colors :  "
        numEntry.textAlignment = .left
        numEntry.textColor = theme.textColor
        numEntry.font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.thin)
        numEntry.text = "\(selectedCount)"
        numEntry.keyboardType = UIKeyboardType.numberPad
        numEntry.frame.size.width = UISettings.panelHeight
        numEntry.frame.size.height = UISettings.panelHeight * 0.8
        numEntry.delegate = self
        //init toolbar
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem:    .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.textEditDoneAction))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        numEntry.inputAccessoryView = toolbar

        
        schemeLabel.text = "Color Scheme :  "
        schemeSelector.delegate = self
        schemeSelector.dataSource = self
        buildSchemeList()
        schemeSelector.showsSelectionIndicator = true
        schemeSelector.frame.size.width = (displayWidth / 2) - 8
        schemeSelector.frame.size.height = UISettings.panelHeight * 0.8
        schemeSelector.setValue(theme.titleTextColor, forKeyPath: "textColor")
        
        
        // layout the items
        parameterView.addSubview(seedLabel)
        parameterView.addSubview(seedButton)
        parameterView.addSubview(numLabel)
        parameterView.addSubview(numEntry)
        parameterView.addSubview(schemeLabel)
        parameterView.addSubview(schemeSelector)
        
        let w:CGFloat = (parameterView.frame.size.width / 2) - 8
        let h:CGFloat = min ((parameterView.frame.size.height / 4), UISettings.panelHeight)
        let pad:CGFloat = 2
        
        // line up the labels on the left
        seedLabel.anchorInCorner(.topLeft, xPad: pad, yPad: pad, width: w, height: h)
        numLabel.align(.underMatchingRight, relativeTo: seedLabel, padding: pad, width: w, height: h)
        schemeLabel.align(.underMatchingRight, relativeTo: numLabel, padding: pad, width: w, height: h)
        
        // add the interactive items to the right of their labels
        seedButton.align(.toTheRightCentered, relativeTo: seedLabel, padding: pad*4, width: seedButton.frame.size.width, height: seedButton.frame.size.height)
        numEntry.align(.toTheRightCentered, relativeTo: numLabel, padding: pad*4, width: numEntry.frame.size.width, height: numEntry.frame.size.height)
        schemeSelector.align(.toTheRightCentered, relativeTo: schemeLabel, padding: pad*4, width: schemeSelector.frame.size.width, height: schemeSelector.frame.size.height)
    }

    
    @objc func textEditDoneAction() {
        self.view.endEditing(true)
    }

    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func buildSchemeList(){
        colorSchemeList = [ColorUtilities.ColorSchemeType.complementary.rawValue,
                           ColorUtilities.ColorSchemeType.analogous.rawValue,
                           ColorUtilities.ColorSchemeType.monochromatic.rawValue,
                           ColorUtilities.ColorSchemeType.triadic.rawValue,
                           ColorUtilities.ColorSchemeType.tetradic.rawValue,
                           ColorUtilities.ColorSchemeType.splitComplimentary.rawValue,
                           ColorUtilities.ColorSchemeType.equidistant.rawValue]
        
    }
    
    
    func layoutColorScheme() {
        colorSchemeView = ColorSchemeView()
        colorSchemeView.frame.size.height = UISettings.panelHeight * 3
        colorSchemeView.frame.size.width = displayWidth
        //colorSchemeView.flatten = false
        colorSchemeView.flatten = true
    }
    
    
    
    func layoutControls(){
        controlView.frame.size.width = displayWidth
        controlView.frame.size.height = UISettings.panelHeight
    
        // build a view with a "Done" Button and a "Cancel" button
        let cancelButton:BorderedButton = BorderedButton()
        cancelButton.frame.size.width = displayWidth / 3.0
        cancelButton.frame.size.height = UISettings.panelHeight - 16
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.useGradient = true
        cancelButton.backgroundColor = theme.highlightColor
        controlView.addSubview(cancelButton)
        
        let doneButton:BorderedButton = BorderedButton()
        doneButton.frame.size = cancelButton.frame.size
        doneButton.setTitle("Done", for: .normal)
        doneButton.useGradient = true
        doneButton.backgroundColor = theme.highlightColor
        controlView.addSubview(doneButton)
        
        // distribute across the control view
        controlView.groupInCenter(group: .horizontal, views: [doneButton, cancelButton], padding: 16, width: doneButton.frame.size.width, height: doneButton.frame.size.height)

        // add touch handlers
        doneButton.addTarget(self, action: #selector(self.doneDidPress), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)

    }
    
    private func updateColors(){
        DispatchQueue.main.async(execute: {
            self.colorSchemeView.displayColors(seed:self.selectedColor, count:self.selectedCount, type:self.selectedColorScheme)
        })
    }

    
    fileprivate func setScheme(_ scheme:ColorUtilities.ColorSchemeType){
        if scheme != selectedColorScheme {
            selectedColorScheme = scheme
            updateColors()
        }
    }
    
    fileprivate func setNumColours(_ num:Int){
        if (num > 0) && (num<32){ // arbitrary limits
            selectedCount = num
            updateColors()
        } else {
            log.error("No. colours out of range: \(num)")
        }
    }
    
    fileprivate func changeSeedColor(_ color:UIColor){
        selectedColor = color
        DispatchQueue.main.async(execute: {
            self.seedButton.setColor(self.selectedColor)
            self.updateColors()
        })
        
    }
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    @objc func seedColorDidPress(){
        log.verbose("Seed Colour pressed")
        let vc = ColorPickerController()
        vc.delegate = self
        vc.setColor(selectedColor)
        present(vc, animated: true, completion: nil)
    }
    
    @objc func backDidPress(){
        log.verbose("Back pressed")
        // NOTE: in this case, back is the same as cancel
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion:  { self.delegate?.colorSchemeCompleted(scheme: []) })
            return
        }
    }

    @objc func cancelDidPress(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion:  { self.delegate?.colorSchemeCompleted(scheme: []) })
            return
        }
    }
    
    @objc func doneDidPress(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion:  { self.delegate?.colorSchemeCompleted(scheme: self.colorSchemeView.getScheme()) })
            return
        }
    }

    
} // ColorSchemeViewController


//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////


// UIPicker stuff

extension ColorSchemeViewController: UIPickerViewDelegate {
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //log.verbose("[\(row)]: \(colorSchemeList[row])")
        return colorSchemeList[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.thin)
            pickerLabel?.textAlignment = .center
        }
        if (row>=0) && (row<colorSchemeList.count){
            pickerLabel?.text = colorSchemeList[row]
            pickerLabel?.textColor = theme.textColor
            pickerLabel?.textAlignment = .left
        } else {
            log.error("Invalid row index:\(row)")
            pickerLabel?.text = "unknown"
            pickerLabel?.textColor = theme.highlightColor
        }

        return pickerLabel!
    }
    
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        if (row>=0) && (row<colorSchemeList.count){
            log.verbose("Selected [\(row)]: \(colorSchemeList[row])")
            let scheme = ColorUtilities.ColorSchemeType(rawValue:colorSchemeList[row])
            setScheme(scheme!)
        } else {
            log.error("Invalid row index:\(row)")
        }
    }
}

extension ColorSchemeViewController: UIPickerViewDataSource{
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //log.verbose("#items:\(colorSchemeList.count)")
        return colorSchemeList.count
    }
    
    
}

// UITextFieldStuff

extension ColorSchemeViewController: UITextInputTraits {
    
    // force the numeric keypad
    private var keyboardType: UIKeyboardType {
        get{
            return UIKeyboardType.numberPad
        }
    }
}

extension ColorSchemeViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            let n:Int? = Int(text)
            setNumColours(n!)
        }
    }
    
    func textField(_ textFieldToChange: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // limit to 4 characters
        let characterCountLimit = 2
        
        // We need to figure out how many characters would be in the string after the change happens
        let startingLength = textFieldToChange.text?.count ?? 0
        let lengthToAdd = string.count
        let lengthToReplace = range.length
        
        let newLength = startingLength + lengthToAdd - lengthToReplace
        
        return newLength <= characterCountLimit
    }
    
    private func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ColorSchemeViewController: ColorPickerControllerDelegate {
    func colorPicked(_ color: UIColor?) {
        if color != nil {
            self.changeSeedColor(color!)
        }
    }
}
