import SwiftUI

struct FocusableTextField: UIViewRepresentable {
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FocusableTextField

        init(_ parent: FocusableTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            // Remove spaces from the input
            let filteredText = textField.text?.replacingOccurrences(of: " ", with: "") ?? ""
            parent.text = filteredText
            textField.text = filteredText
        }

    }

    @Binding var text: String
    var placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        textField.placeholder = placeholder
        textField.font = UIFont(name: "Marker Felt", size: 24)
        textField.delegate = context.coordinator
        textField.borderStyle = .roundedRect
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        if !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }
}
