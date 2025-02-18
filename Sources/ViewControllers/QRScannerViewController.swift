//
//  Untitled.swift
//  LottoAlert
//
//  Created by YangJeongMu on 2/13/25.
//

import UIKit
import AVFoundation
import WebKit

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    // 가이드라인 뷰 추가
    private let guideView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor(red: 245/255, green: 184/255, blue: 0/255, alpha: 1.0).cgColor
        view.layer.borderWidth = 2
        view.backgroundColor = .clear
        return view
    }()
    
    // 웹뷰 추가
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.isHidden = true // 초기에는 숨김
        return webView
    }()
    
    // 컨테이너 뷰 추가 (카메라 미리보기용)
    private let cameraContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }
    
    private func setupUI() {
        // 컨테이너 뷰 설정
        view.addSubview(cameraContainer)
        view.addSubview(webView)
        
        cameraContainer.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 카메라 컨테이너는 상단 절반
            cameraContainer.topAnchor.constraint(equalTo: view.topAnchor),
            cameraContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            // 웹뷰는 하단 절반
            webView.topAnchor.constraint(equalTo: cameraContainer.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCamera() {
        // 캡처 세션 설정
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            failed()
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        // 프리뷰 레이어 설정 (카메라 컨테이너에 추가)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = cameraContainer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        cameraContainer.layer.addSublayer(previewLayer)
        
        // 가이드라인 뷰 추가
        setupGuideView()
        
        // 스캔 영역 설정
        setupScanningArea()
        
        // 스캔 시작
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    private func setupGuideView() {
        cameraContainer.addSubview(guideView)
        guideView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            guideView.centerXAnchor.constraint(equalTo: cameraContainer.centerXAnchor),
            guideView.centerYAnchor.constraint(equalTo: cameraContainer.centerYAnchor),
            guideView.widthAnchor.constraint(equalToConstant: 150),
            guideView.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        guideView.layer.cornerRadius = 10
    }
    
    private func setupScanningArea() {
        guard let metadataOutput = captureSession.outputs.first as? AVCaptureMetadataOutput else { return }
        let rectOfInterest = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        metadataOutput.rectOfInterest = rectOfInterest
    }

    func failed() {
        let ac = UIAlertController(title: "스캐닝 불가",
                                  message: "디바이스가 QR코드 스캐닝을 지원하지 않습니다.",
                                  preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "확인", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
    }
    
    func found(code: String) {
        print("QR코드 내용: \(code)")
        
        // QR 코드 URL을 새로운 도메인으로 변환
        var updatedCode = code
        if code.contains("nlotto.co.kr") {
            // 예전 도메인을 새로운 도메인으로 교체
            updatedCode = code.replacingOccurrences(of: "qr.nlotto.co.kr", with: "qr.dhlottery.co.kr")
        }
        
        // 여기서 updatedCode를 사용하도록 수정
        if let url = URL(string: updatedCode) { // code 대신 updatedCode 사용
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            let alert = UIAlertController(title: "QR코드 스캔 완료",
                                        message: "당첨 결과를 확인하시겠습니까?",
                                        preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
                let request = URLRequest(url: url)
                self?.webView.isHidden = false
                self?.webView.load(request)
            })
            
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            present(alert, animated: true)

        } else {
            // URL이 아닌 경우 처리
            let alert = UIAlertController(title: "알림",
                                        message: "올바른 로또 QR코드가 아닙니다.",
                                        preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraContainer.bounds
    }
}
