public protocol TextualElement: GUIElement {
    var richText: RichText? { get set }
}

public protocol Label: TextualElement {}
public protocol Button: GUIElement {}
public protocol Table: GUIElement {}
public protocol TableCell: GUIElement {}
public protocol TableRow: GUIElement {}

public protocol Image: GUIElement {
    var imageFile: ImageFile? { get set }
}

public protocol Navigator: class, GUIElement {
    associatedtype Element: GUIElementRepresentable
    
    func forward(to element: Element)
    func backwards()
}
