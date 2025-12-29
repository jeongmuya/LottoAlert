# 로또 알림 (Lotto Alert)
![Frame 636](https://github.com/user-attachments/assets/ca22e0e1-32b4-4103-b50b-f4583d29b48d)
# 🎱 LottoAlert (로또 알림 & 판매점 지도)

**내 주변 로또 판매점을 찾고, QR 코드로 당첨을 즉시 확인하는 iOS 앱**

<img src="https://img.shields.io/badge/iOS-15.0+-silver?style=flat-square&logo=apple" /> <img src="https://img.shields.io/badge/Swift-5.0-orange?style=flat-square&logo=swift" /> <img src="https://img.shields.io/badge/Xcode-14.0+-blue?style=flat-square&logo=xcode" />

## 📱 프로젝트 소개
'LottoAlert'은 로또 구매자들의 편의를 위해 개발된 올인원 유틸리티 앱입니다.
사용자 위치 기반으로 가까운 판매점을 지도에 표시하고, 구매한 로또의 QR 코드를 스캔하여 당첨 결과를 앱 내에서 바로 확인할 수 있습니다.

## 🛠 Tech Stack
- **Language**: Swift 5
- **UI Framework**: UIKit (Code-based UI), SnapKit
- **Map & Location**: MapKit, CoreLocation
- **Media**: AVFoundation (QR Scanning), WebKit
- **Animation**: Lottie (당첨 효과)
- **Design Pattern**: MVC, Singleton

## 💡 주요 기능
1. **내 주변 판매점 찾기**: CoreLocation을 활용해 사용자 위치를 추적하고, MapKit 위에 판매점 위치를 커스텀 마커로 표시합니다.
2. **도보 경로 안내**: 선택한 판매점까지의 도보 경로(Polyline)를 지도 위에 시각적으로 그려줍니다.
3. **QR 당첨 확인**: 카메라로 로또 용지의 QR 코드를 스캔하면, 동행복권 모바일 페이지를 인앱 브라우저로 띄워 결과를 보여줍니다.
4. **번호 추천 (예정)**: 랜덤 알고리즘을 활용한 로또 번호 추천 기능.

## 🚀 Trouble Shooting (문제 해결)

### 1. 구형 로또 용지(QR) 도메인 호환성 문제 해결
- **문제 상황**: 복권 사업자가 변경되면서 과거 로또 용지의 QR 코드 도메인(`nlotto.co.kr`)이 현재 도메인(`dhlottery.co.kr`)과 달라 접속 불가 현상 발생.
- **해결**: QR 코드 인식 시 URL 문자열을 파싱하여, 구형 도메인이 감지되면 자동으로 신규 도메인으로 치환(String Replacement)하여 연결하도록 로직 개선.

### 2. 지도 오버레이(Overlay) 중복 렌더링 방지
- **문제 상황**: 경로 찾기 기능을 연속으로 사용 시, 지도 위에 파란색 경로 선이 계속 겹쳐서 표시됨.
- **해결**: 새로운 경로 요청(`findRoute`)이 들어올 때마다 `mapView.removeOverlay`를 호출하여 기존 객체를 메모리에서 해제한 후 새 경로만 그리도록 최적화.

### 3. UI 개발 생산성 향상
- **개선**: 초기 `NSLayoutConstraint`로 작성된 방대한 UI 코드를 **SnapKit**을 도입하여 리팩토링. 코드 라인 수를 줄이고 가독성을 높여 유지보수 효율을 증대시킴.
