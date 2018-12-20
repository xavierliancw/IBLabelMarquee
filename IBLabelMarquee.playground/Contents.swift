//: A UIKit based Playground for presenting user interface

import UIKit
import PlaygroundSupport

@IBDesignable class IBView: UIView
{
    @IBInspectable var cornerRadius: CGFloat {
        get {return layer.cornerRadius}
        set {layer.cornerRadius = newValue}
    }
    @IBInspectable var borderWidth: CGFloat {
        get {return layer.borderWidth}
        set {layer.borderWidth = newValue}
    }
    @IBInspectable var borderColor: UIColor? {
        get {
            if layer.borderColor != nil
            {
                return UIColor(cgColor: layer.borderColor!)
            }
            return nil
        }
        set {layer.borderColor = newValue?.cgColor}
    }
}


struct SVCAutoLayout
{
    static func embed(thisVw: UIView, withinThisVw: UIView, withInset: CGFloat = 0)
    {
        thisVw.translatesAutoresizingMaskIntoConstraints = false
        withinThisVw.addSubview(thisVw)
        thisVw.centerXAnchor.constraint(equalTo: withinThisVw.centerXAnchor).isActive = true
        thisVw.centerYAnchor.constraint(equalTo: withinThisVw.centerYAnchor).isActive = true
        thisVw.heightAnchor.constraint(equalTo: withinThisVw.heightAnchor,
                                       constant: -withInset).isActive = true
        thisVw.widthAnchor.constraint(equalTo: withinThisVw.widthAnchor,
                                      constant: -withInset).isActive = true
    }
    
    static func cover(vw: UIView, with coveringVw: UIView)
    {
        guard let superVw = vw.superview else {
            return
        }
        superVw.addSubview(coveringVw)
        coveringVw.translatesAutoresizingMaskIntoConstraints = false
        coveringVw.widthAnchor.constraint(equalTo: vw.widthAnchor).isActive = true
        coveringVw.heightAnchor.constraint(equalTo: vw.heightAnchor).isActive = true
        coveringVw.centerYAnchor.constraint(equalTo: vw.centerYAnchor).isActive = true
        coveringVw.centerXAnchor.constraint(equalTo: vw.centerXAnchor).isActive = true
    }
}

@IBDesignable class IBLabelMarquee: IBView
{
    //MARK: Default Values
    
    private static let DEF_INSET: CGFloat = 5
    
    //MARK: Inspectable Properties
    
    @IBInspectable var text: String? {
        get {return lbl.text}
        set {
            lbl.text = newValue
            layoutIfNeeded()    //Redraw bounds after setting text
            scrollVw.contentSize.width = lbl.bounds.width + contentInset.left + contentInset.right
        }
    }
    @IBInspectable var textColor: UIColor? {
        get {return lbl.textColor}
        set {lbl.textColor = newValue}
    }
    @IBInspectable var contentInset: UIEdgeInsets {
        get {return _contentInset}
        set {
            _contentInset = newValue
            adjustConstraintsToMatch(newInset: newValue)
        }
    }
    @IBInspectable var font: UIFont? {
        get {return lbl.font}
        set {lbl.font = newValue}
    }
    @IBInspectable var timeDelay: TimeInterval = 12 {didSet {startMarquee()}}
    @IBInspectable var animationDuration: TimeInterval = 4 {didSet {startMarquee()}}
    @IBInspectable var animationDelay: TimeInterval = 1 {didSet {startMarquee()}}
    
    //MARK: Private Properties
    
    private let lbl = UILabel(frame: .zero)
    private let scrollVw = UIScrollView(frame: .zero)
    private var _contentInset = UIEdgeInsets(top: DEF_INSET, left: DEF_INSET,
                                             bottom: DEF_INSET, right: DEF_INSET)
    private var lblLeadCon: NSLayoutConstraint?
    private var lblTopCon: NSLayoutConstraint?
    private var lblBotCon: NSLayoutConstraint?
    private var animationTimer: Timer?
    private var endOffset: CGPoint {
        return CGPoint(x: scrollVw.contentSize.width - scrollVw.bounds.width, y: 0)
    }
    private var initialized = false
    
    //MARK: Lifecycle
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    override func layoutSublayers(of layer: CALayer)
    {
        super.layoutSublayers(of: layer)
        if !initialized
        {
            initialized = true
            startMarquee()
        }
    }
    
    //MARK: Functions
    
    func startMarquee()
    {
        layoutIfNeeded()    //Make sure to update bound values
        
        //Determine if marquee animation is even necessary
        print(lbl.bounds.width)
        print(contentInset)
        print(scrollVw.bounds.width)
        if lbl.bounds.width + contentInset.left + contentInset.right > scrollVw.bounds.width
        {
            animationTimer?.invalidate()
            animationTimer = Timer.scheduledTimer(withTimeInterval: timeDelay, repeats: true)
            { [weak self] (inTimer) in
                guard let self = self else {return}
                UIView.animate(withDuration: self.animationDuration, animations: {
                    self.scrollVw.contentOffset.x = self.endOffset.x
                }, completion: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.animationDelay,
                                                  execute: {
                                                    UIView.animate(withDuration: self.animationDuration)
                                                    {
                                                        self.scrollVw.contentOffset.x = CGFloat(0)
                                                    }
                    })
                })
            }
        }
    }
    
    //MARK: Private Functions
    
    private func setup()
    {
        //Set up the scroll view
        SVCAutoLayout.embed(thisVw: scrollVw, withinThisVw: self)
        scrollVw.isScrollEnabled = false
        
        //Set up lbl
        lbl.textColor = UIColor.white
        lbl.numberOfLines = 1
        scrollVw.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.centerYAnchor.constraint(equalTo: scrollVw.centerYAnchor).isActive = true
        lbl.heightAnchor.constraint(equalTo: scrollVw.heightAnchor).isActive = true
        lblLeadCon = lbl.leftAnchor.constraint(equalTo: scrollVw.leftAnchor,
                                               constant: contentInset.left)
        lblLeadCon?.isActive = true
    }
    
    private func adjustConstraintsToMatch(newInset: UIEdgeInsets)
    {
        //Adjust leading inset
        lblLeadCon?.isActive = false
        lblLeadCon = lbl.leftAnchor.constraint(equalTo: scrollVw.leftAnchor,
                                               constant: newInset.left)
        lblLeadCon?.isActive = true
        
        //Redraw bounds and adjust right inset
        layoutIfNeeded()
        scrollVw.contentSize.width = lbl.bounds.width + contentInset.left + contentInset.right
    }
}

class MyViewController : UIViewController {
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        
        let label = UILabel()
        label.frame = CGRect(x: 150, y: 200, width: 300, height: 20)
        label.text = "Hello World!"
        label.textColor = .black
        
        view.addSubview(label)
        self.view = view
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let marqLbl = IBLabelMarquee(frame: .zero)
        marqLbl.cornerRadius = 4
        marqLbl.backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.8)
        view.addSubview(marqLbl)
        marqLbl.translatesAutoresizingMaskIntoConstraints = false
        marqLbl.heightAnchor.constraint(equalToConstant: 500).isActive = true
        marqLbl.widthAnchor.constraint(equalToConstant: 200).isActive = true
        marqLbl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        marqLbl.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        marqLbl.text = "YO WASSUijrj alskdjfla laksjf lhiewf ajdfiu"
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
