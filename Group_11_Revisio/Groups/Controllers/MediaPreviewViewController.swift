import UIKit

class MediaPreviewViewController: UIViewController, UIScrollViewDelegate {

    var image: UIImage!

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        setupScrollView()
        setupImageView()
        setupNavigationBar()
        setupDismissGesture()
    }

    private func setupScrollView() {
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = self
        view.addSubview(scrollView)
    }

    private func setupImageView() {
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
    }

    private func setupNavigationBar() {
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareTapped)
        )

        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = shareButton
    }

    private func setupDismissGesture() {
        let swipe = UISwipeGestureRecognizer(
            target: self,
            action: #selector(closeTapped)
        )
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func shareTapped() {
        let vc = UIActivityViewController(
            activityItems: [image!],
            applicationActivities: nil
        )
        present(vc, animated: true)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
