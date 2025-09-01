
import Foundation
import UIKit

public class Player {
    internal var view: PlayerView


    public init() {
        view = PlayerView()
    }
    
    public func getView() -> UIView {
        return view.view
    }
    

}

