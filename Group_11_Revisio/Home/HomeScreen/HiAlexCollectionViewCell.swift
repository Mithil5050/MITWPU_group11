//
//  HiAlexCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 28/11/25.
//

import UIKit
import AVFoundation

// 1. Define Protocol
protocol HiAlexCellDelegate: AnyObject {
    func didTapPlayNow()
}

class HiAlexCollectionViewCell: UICollectionViewCell {

    @IBOutlet var BgView: GradientView!
    @IBOutlet weak var hiAlex: UIView!
    @IBOutlet var PlayNow: UIButton!
    @IBOutlet weak var robotImageView: UIImageView!
    
    // Transparent container that holds the AVPlayerLayer
    private let videoContainerView = UIView()
    
    // Video Player Properties
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    
    // 2. Add Delegate Variable
    weak var delegate: HiAlexCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Style Setup
        hiAlex.layer.cornerRadius = 12
        BgView.layer.cornerRadius = 12
        BgView.backgroundColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1)
        PlayNow.layer.cornerRadius = 15
        
        // Keep the container fully transparent so HEVC-alpha shows through
        videoContainerView.backgroundColor = .clear
        videoContainerView.isHidden = true
        
        // Insert video container into the same parent as robotImageView
        if videoContainerView.superview == nil, let parent = robotImageView.superview {
            parent.insertSubview(videoContainerView, aboveSubview: robotImageView)
        }
        
        setupVideoPlayer()
        
        // 3. Add Target for Button Press
        PlayNow.addTarget(self, action: #selector(playNowTapped), for: .touchUpInside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoContainerView.frame = robotImageView.frame
        playerLayer?.frame = videoContainerView.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Instead of killing the player, we just ensure it's playing
        // or recreate it if it was lost. 
        // For simple apps, calling setupVideoPlayer again is safest to reset state.
        setupVideoPlayer()
    }

    private func setupVideoPlayer() {
        // 1. Clean up previous state
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        playerLooper = nil
        player = nil
        
        // 2. Show static fallback image while loading
        robotImageView.isHidden = false
        videoContainerView.isHidden = true
        
        // 3. Prefer the HEVC-with-alpha version; fall back to the original mp4
        let videoURL: URL
        if let alphaPath = Bundle.main.path(forResource: "robot_wave_alpha", ofType: "mov") {
            videoURL = URL(fileURLWithPath: alphaPath)
        } else if let mp4Path = Bundle.main.path(forResource: "robot_wave", ofType: "mp4") {
            videoURL = URL(fileURLWithPath: mp4Path)
        } else {
            if let gifImage = UIImage.gifImageWithName("robot_wave") {
                robotImageView.image = gifImage
            }
            return
        }
        
        // 4. Use AVQueuePlayer and AVPlayerLooper for SEAMLESS looping
        let playerItem = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.isMuted = true
        self.player = queuePlayer
        
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        // 5. Build the AVPlayerLayer
        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = .resizeAspect
        layer.frame = videoContainerView.bounds
        layer.backgroundColor = UIColor.clear.cgColor
        videoContainerView.layer.addSublayer(layer)
        self.playerLayer = layer
        
        // 6. Start playback, then swap from static image to live video
        queuePlayer.play()
        
        // Small delay to let the first frame load before revealing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.videoContainerView.isHidden = false
            self.robotImageView.isHidden = true
        }
    }
    
    // 4. Handle Action
    @objc func playNowTapped() {
        delegate?.didTapPlayNow()
    }
}
