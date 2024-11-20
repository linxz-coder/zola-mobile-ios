import UIKit

class ViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    // 添加一个属性来跟踪 title 的状态
    private var hasFrontMatterTitle = false
    
    //标题栏：可自定义文件名
    private let filenameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter filename (without .md)"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    //文本框区域
    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    //上传按钮
    private let uploadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Upload to GitHub", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    // 键盘上方的确认按钮视图
    private lazy var keyboardToolbar: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        view.backgroundColor = .systemGray6
        
        let doneButton = UIButton(type: .custom)
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = .systemBlue
        doneButton.layer.cornerRadius = 6
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            doneButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.widthAnchor.constraint(equalToConstant: 60),
            doneButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        insertFrontMatter()
        setupKeyboardHandling()
        setupInputAccessoryViews()
        
        // 双击空白退出编辑：Add double tap gesture
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
        
        filenameTextField.delegate = self
        textView.delegate = self
    }
    
    // 设置输入框的inputAccessoryView
    private func setupInputAccessoryViews() {
        // 创建一个新的实例用于textView和filenameTextField
        let accessoryView = keyboardToolbar
        textView.inputAccessoryView = accessoryView
        filenameTextField.inputAccessoryView = accessoryView
    }
    
    // 确认按钮点击事件
    @objc private func doneButtonTapped() {
        view.endEditing(true)
    }
    
    //双击退出编辑
    @objc private func handleDoubleTap() {
        view.endEditing(true)
    }
    
    //设定初始UI的渲染
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
    
    //设定键盘自动出现和隐藏，不要挡住UI
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
    
    //设置FrontMatter
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
        
        hasFrontMatterTitle = false  // 初始状态设置为 false
    }
    
    //键盘自动出现
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
            as? NSValue)?.cgRectValue else { return }
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        textView.contentInset = contentInsets
        textView.scrollIndicatorInsets = contentInsets
    }
    
    //键盘自动隐藏
    @objc private func keyboardWillHide(notification: NSNotification) {
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
    }
    
    //上传按钮事件
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
    
    //upload button的通知事件
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    //当文件名有内容的时候，才开启上传按钮
    func textViewDidChange(_ textView: UITextView) {
        // 检查是否包含 title = ""
        if let text = textView.text {
            hasFrontMatterTitle = !text.contains("title = \"\"")
            updateUploadButtonState(hasFilename: !filenameTextField.text!.isEmpty)
        }
    }
    
    // 添加新方法来更新按钮状态
    private func updateUploadButtonState(hasFilename: Bool) {
        uploadButton.isEnabled = hasFilename && hasFrontMatterTitle
    }
}
