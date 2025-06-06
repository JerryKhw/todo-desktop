# 📝 TODO Desktop

**TODO Desktop**은 Flutter로 개발된 **Windows 전용 TODO 앱**입니다.

## 🛠️ Installation

### 1. Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (installed and added to your system PATH)
- [fvm](https://fvm.app/docs/getting_started/installation) (Flutter Version Manager)


### 2.  Install the Flutter version used in this project
```bash
fvm install
```

### 3. Install project dependencies
```bash
fvm flutter pub get
```

### 4.  Generate code (for freezed, json_serializable, etc.)
```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Run the app on Windows
```bash
fvm flutter run -d windows
```

## ⚠️ Known Issues

- 한글 입력 시 텍스트 커서가 한칸 앞에 있음 [관련 Issue #140739](https://github.com/flutter/flutter/issues/140739)
- flutter_quill onKeyPressed 작동하지 않는 현상이 있음
- window_manager_plus 창 닫을 시 프로그램 자체가 죽는 현상이 있음