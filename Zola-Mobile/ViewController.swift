import UIKit

class ViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    private let filenameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter filename (without .md)"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let uploadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Upload to GitHub", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        insertFrontMatter()
        setupKeyboardHandling()
        
        // Add double tap gesture
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
        
        filenameTextField.delegate = self
        textView.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 1.0
        textView.addGestureRecognizer(longPress)
    }
    
    @objc private func handleDoubleTap() {
        view.endEditing(true)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(filenameTextField)
        view.addSubview(textView)
        view.addSubview(uploadButton)
        
        NSLayoutConstraint.activate([
            filenameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            filenameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filenameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filenameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            textView.topAnchor.constraint(equalTo: filenameTextField.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: uploadButton.topAnchor, constant: -16),
            
            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            uploadButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    private func insertFrontMatter() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        textView.text = """
        +++
        title = ""
        date = \(today)
        +++
        
        """
    }
    
    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            textView.resignFirstResponder()
        }
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
            as? NSValue)?.cgRectValue else { return }
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        textView.contentInset = contentInsets
        textView.scrollIndicatorInsets = contentInsets
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
    }
    
    @objc private func uploadButtonTapped() {
        guard let filename = filenameTextField.text, !filename.isEmpty else { return }
        let content = textView.text!
        GitHubService.shared.uploadContent(content: content, filename: "\(filename).md") { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.showAlert(message: "Successfully uploaded!")
                case .failure(let error):
                    self.showAlert(message: "Upload failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let updatedText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
        uploadButton.isEnabled = !updatedText.isEmpty
        return true
    }
}
