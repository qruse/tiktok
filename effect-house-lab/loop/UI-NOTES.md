# Effect House 화면 메모 (v5.15.0)

알게 된 메뉴 위치, 좌표, 함정을 적는다. 좌표는 창 위치에 따라 달라지므로 창 기준 상대 위치와 함께 적는다.

## 실행
- 실행 파일: `C:\Users\Public\EHTest\Launch-EffectHouse.cmd`
- 프로세스 이름: `Effect House`
- 계정: 로그인 상태다. 2026-10-03 기준 오른쪽 위에 프로필 "h"가 보인다.

## 홈 화면 (2026-10-03 확인)
- 창은 왼쪽 모니터에 있었다. 캡처 원점은 (-1080,-209), 크기는 3000x1920이다.
- 위쪽 탭: Home, Templates, Rewards, Projects, Analytics, Knowledge Hub
- 왼쪽 버튼: Create project, Open project
- Challenges 패널에 Game Effect Challenge(최대 $1,000, 86일 남음)와 Halloween Warmup Sub Challenge가 있다.
- Trends 패널: Halloween, iPhone Duo, American Horror Story

## 내장 자동화 서버 (2026-10-03 회차 1 발견) — GUI 클릭보다 우선 사용
- Effect House가 켜져 있으면 MCP 서버 "tteh"가 `http://127.0.0.1:9100/mcp`에 열린다(포트는 바뀔 수 있음, 도구가 자동 탐색).
- 호출 도구: `loop/tools/eh-mcp.ps1 -Action list | schema -Tool 이름 | call -Tool 이름 -ArgsJson '{...}'`
- 주요 도구: describe_project, get_scene, edit_by_dsl(씬 편집), capture_preview(미리보기 캡처), interact_by_dsl(미리보기 조작), get_script_logs, set_preview_video, list_preview_videos, save_project, query_knowledge, search_library, generate_image.
- 사용 설명서: `C:\Users\Public\EHTest\App\Resources\ask-ai\workspace\AGENTS.md`, `EDIT_DSL_REFERENCE.md`, `skills\`
- SDK 타입: `C:\Users\Public\EHTest\App\Resources\BuiltinResource\UserAPI\APJS.d.ts` (읽기만, App 폴더 수정 금지)

### MCP 사용 요령 (2026-10-03 회차 3)
- `set_preview_video`의 인자 이름은 `video_name`이다(예: `{"video_name":"preview_face_idle||3"}`). "replaced by reload" 오류가 떠도 영상은 바뀐다(`get_current_preview_video`로 확인).
- 내장 얼굴 영상 idle 1·2·3 모두 로컬에 있다(idle 3은 `AppData\Roaming\EffectHouse\Shared\...`에 받아져 있음). idle 2만 깜빡인다(4초 간격).
- `transport_preview_property`는 success를 돌려줘도 BlinkGame 값이 바뀌지 않았다. 임시로 값을 바꿀 때는 `edit_by_dsl` `set_component`(guid r20)로 바꾸고 끝나면 되돌린다.
- `get_script_logs`는 출력이 길다. `| Out-String | ConvertFrom-Json | Select-Object -Last N`으로 필요한 줄만 본다.
- 덮침처럼 짧은 장면은 `steps=1, idleStep=2`로 임시 저장하고 idle 1 영상에서 reset 후 약 4초 뒤부터 연속 screenshot을 찍으면 잡힌다.
- **`trending_effects`를 쓰지 않는다.** 썸네일 없는 선택 창을 GUI에 띄우고, 누가 Select/Cancel을 누를 때까지 응답하지 않는다. 닫지 않고 두면 창이 쌓이고 미리보기 녹화가 막힌다. 고른 1개의 표지 URL(cover_url)만 돌려준다. 상위 효과 표지가 꼭 필요하면 백그라운드로 호출하고 8초 뒤 Select(1239,650)를 누른다.

### 미리보기 녹화 (2026-10-03 회차 3)
- MCP `record_preview_video_mp4`는 "VESDK savingRecording did not produce ..."로 계속 실패했다(창을 다 닫고, Desktop 폴더를 만든 뒤에도 실패).
- 우회로: `loop/tools/record-run.ps1 -Video "preview_face_idle||2" -Out C:\Users\Public\EHTest\Projects\_src\x.mp4`. 미리보기 패널 녹화 버튼(1284,594, 창 최대화 기준)을 눌러 녹화하고 저장 창에 경로를 붙여넣는다. 720x1280 30fps, 약 50MB/33초, **소리 없음**.
  - 처음 누를 때 "No audio will be recorded" 확인 창이 뜬다. "Don't show again"을 체크해 두었다.
  - 저장 창 기본 위치 `C:\Users\Public\EHTest\Desktop`이 없어서 오류가 났다. 폴더를 만들어 두었다.
  - 녹화 파일은 버튼을 누르고 약 3.7초 뒤부터 담긴다. 그래서 2.5초짜리 시작 화면(DON'T BLINK)이 빠진다. 데모 영상용으로는 다른 방법이 필요하다.
- 미리보기 패널(작은 화면)에서는 필름 스트립 양옆에 흰 얼룩이 보이지만, MCP 스크린샷과 녹화 파일에는 없다. 패널 표시 문제로 보이며 휴대폰에서는 확인 전이다.
- 프레임 추출: imageio_ffmpeg에 든 ffmpeg(`%LOCALAPPDATA%\Packages\PythonSoftwareFoundation.Python.3.11_qbz5n2kfra8p0\LocalCache\local-packages\Python311\site-packages\imageio_ffmpeg\binaries\*.exe`)를 쓴다.

## 제출 (2026-10-03 첫 제출 때 확인, 창 최대화 기준 좌표)
- 오른쪽 위 **Submit**(1828,50)을 누르면 Publish Effect 창이 열린다.
  - 필수: What do you want to submit(새 효과 / 기존 효과 업데이트), Effect name(25자 이내, 중복 불가), Effect icon(1~2개)
  - 선택: Hint, Default sound, Challenge, Trend, Demo video
- **Demo video는 15초 이하, 32MB 이하, MOV/MP4다.** 녹화본을 ffmpeg로 잘라 쓴다.
- **아이콘은 직접 그린 그림을 그대로 올릴 수 없다.**
  - "Create Icon" 창은 템플릿 인물 사진(또는 업로드한 인물 사진)에 효과를 입혀서 아이콘을 만든다.
  - 그 창의 슬라이더는 시간 이동이 아니라 확대 조절이다.
  - 원하는 순간을 담으려면 재생(⟳ 1262,617) 후 일시정지(1213,617)로 멈춘다.
  - 형체가 다가온 장면을 담으려고 `idleStep`을 0.7로 잠깐 줄였다. 약 5.6초 뒤에 멈추면 형체가 어깨 뒤로 다가온 장면이 잡혔다. **제출 전에 반드시 원래 값으로 되돌린다.**
  - 아이콘 2개 모드에서 "Create another"를 누르면 아이콘 1이 계속 재생되다가 결과 화면으로 바뀌어 버렸다. 아이콘 1개를 만들고 Submit → "Submit effect with 1 icon?" → Submit 순서로 하는 게 안전하다.
- 챌린지를 고르면 약관 동의 체크박스(권리 확인, 이메일 공유)가 나온다. 사용자 동의를 받고 체크한다(2026-10-03 동의 받음).
- 제출하면 "Your effect has been submitted! … usually takes 24 hours" 창이 뜨고, 그 아래 "Manage effects" 링크가 있다.

## 창 다루기
- 창이 두 모니터에 걸쳐 있으면 오른쪽 모니터(원점 0,0, 1920x1080)로 옮겨 최대화해서 쓴다. `scr.ps1 -Action max -Text "Effect House"` (단, 팝업이 떠 있으면 팝업이 최대화되니 팝업을 먼저 닫는다).
- 프로젝트를 처음 열면 안내 팝업 2개(Customize Workspace Layout, Keyboard shortcuts)와 Windows 방화벽 허용 창이 뜬다. 방화벽 창은 "취소"를 눌렀다(시스템 보안 설정은 사용자 몫).
- 다른 이름으로 저장(Ctrl+Shift+S) 창은 기본 위치 `C:\Users\Public\EHTest\Desktop` 없음 오류를 먼저 띄운다. 확인 후 파일 이름 칸에 전체 경로를 붙여넣고(클립보드 + Ctrl+V, 한글 입력기 때문에 직접 타이핑 금지) 저장하면 그 이름의 폴더 안에 `effect.ehproj`가 생긴다.

## 함정
- 한글 사용자 경로에서 실행하면 바로 꺼진다. 반드시 위 cmd로 실행한다.
