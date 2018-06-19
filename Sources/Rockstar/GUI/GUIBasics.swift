public protocol TextualElement: GUIElement {
    var text: RichText? { get set }
}

public protocol Label: TextualElement {}
public protocol Button: GUIElement {}
public protocol Table: GUIElement {}
public protocol TableCell: GUIElement {}
public protocol TableRow: GUIElement {}
