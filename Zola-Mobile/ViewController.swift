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
    
    // 添加作者输入框
    private let authorTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter author name (optional)"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 36).isActive = true // 降低高度
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
        authorTextField.delegate = self
        
        // 添加作者输入框的文本变化监听
        authorTextField.addTarget(self, action: #selector(authorTextChanged), for: .editingChanged)
        // 添加作者输入框的输入辅助视图
        authorTextField.inputAccessoryView = keyboardToolbar
    }
    
    // 添加作者文本变化的处理方法
    @objc private func authorTextChanged() {
        insertFrontMatter()
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
        view.addSubview(authorTextField) // 添加作者输入框
        view.addSubview(textView)
        view.addSubview(uploadButton)
        
        NSLayoutConstraint.activate([
              filenameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
              filenameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
              filenameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
              filenameTextField.heightAnchor.constraint(equalToConstant: 36), // 统一高度
              
              authorTextField.topAnchor.constraint(equalTo: filenameTextField.bottomAnchor, constant: 4), // 减小间距
              authorTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
              authorTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
              
              textView.topAnchor.constraint(equalTo: authorTextField.bottomAnchor, constant: 8), // 减小间距
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
        
        var frontMatter = """
            +++
            title = ""
            date = \(today)
            """
        
        // 如果有作者，添加作者信息
       if let author = authorTextField.text, !author.isEmpty {
           frontMatter += "\nauthors = [\"\(author)\"]"
       }
       
       frontMatter += "\n+++\n\n"
       
       textView.text = frontMatter
        
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
           
           // 首先显示确认上传的对话框
           let confirmAlert = UIAlertController(title: "Confirm Upload",
                                              message: "Do you want to upload this file?",
                                              preferredStyle: .alert)
           
           let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
           
           let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
               self?.showPathSelectionAlert(filename: filename)
           }
           
           confirmAlert.addAction(cancelAction)
           confirmAlert.addAction(confirmAction)
           
           present(confirmAlert, animated: true)
       }
    
    //用户选择路径
    private func showPathSelectionAlert(filename: String) {
           let pathAlert = UIAlertController(title: "Select Upload Path",
                                           message: "Choose or enter a path (default: content)",
                                           preferredStyle: .actionSheet)
           
           // 预定义的路径选项
           let paths = ["/content/blog", "/content/shorts", "/content/books"]
           
           // 添加预定义路径选项
           for path in paths {
               let pathAction = UIAlertAction(title: path, style: .default) { [weak self] _ in
                   self?.uploadContent(filename: filename, path: path)
               }
               pathAlert.addAction(pathAction)
           }
           
           // 添加自定义路径选项
           let customAction = UIAlertAction(title: "Custom Path", style: .default) { [weak self] _ in
               self?.showCustomPathInput(filename: filename)
           }
           
           // 添加默认路径选项
           let defaultAction = UIAlertAction(title: "Default (content)", style: .default) { [weak self] _ in
               self?.uploadContent(filename: filename, path: "/content")
           }
           
           let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
           
           pathAlert.addAction(customAction)
           pathAlert.addAction(defaultAction)
           pathAlert.addAction(cancelAction)
           
           // iPad 支持
           if let popoverController = pathAlert.popoverPresentationController {
               popoverController.sourceView = uploadButton
               popoverController.sourceRect = uploadButton.bounds
           }
           
           present(pathAlert, animated: true)
       }
    
    //自定义路径
    private func showCustomPathInput(filename: String) {
            let customPathAlert = UIAlertController(title: "Enter Custom Path",
                                                  message: "Start with /content/",
                                                  preferredStyle: .alert)
            
            customPathAlert.addTextField { textField in
                textField.placeholder = "/content/your-path"
                textField.text = "/content/"
            }
            
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
                guard let customPath = customPathAlert.textFields?.first?.text,
                      !customPath.isEmpty else { return }
                self?.uploadContent(filename: filename, path: customPath)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            customPathAlert.addAction(confirmAction)
            customPathAlert.addAction(cancelAction)
            
            present(customPathAlert, animated: true)
        }
    
    //上传content
    private func uploadContent(filename: String, path: String) {
           let content = textView.text!
           // 移除路径开头的斜杠（如果存在）
           let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
           
           GitHubService.shared.uploadContent(content: content,
                                            filename: "\(filename).md",
                                            path: cleanPath) { [weak self] result in
               DispatchQueue.main.async {
                   switch result {
                   case .success:
                       self?.showAlert(message: "Successfully uploaded to \(path)!")
                   case .failure(let error):
                       self?.showAlert(message: "Upload failed: \(error.localizedDescription)")
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
