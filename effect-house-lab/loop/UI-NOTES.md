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

## 창 다루기
- 창이 두 모니터에 걸쳐 있으면 오른쪽 모니터(원점 0,0, 1920x1080)로 옮겨 최대화해서 쓴다. `scr.ps1 -Action max -Text "Effect House"` (단, 팝업이 떠 있으면 팝업이 최대화되니 팝업을 먼저 닫는다).
- 프로젝트를 처음 열면 안내 팝업 2개(Customize Workspace Layout, Keyboard shortcuts)와 Windows 방화벽 허용 창이 뜬다. 방화벽 창은 "취소"를 눌렀다(시스템 보안 설정은 사용자 몫).
- 다른 이름으로 저장(Ctrl+Shift+S) 창은 기본 위치 `C:\Users\Public\EHTest\Desktop` 없음 오류를 먼저 띄운다. 확인 후 파일 이름 칸에 전체 경로를 붙여넣고(클립보드 + Ctrl+V, 한글 입력기 때문에 직접 타이핑 금지) 저장하면 그 이름의 폴더 안에 `effect.ehproj`가 생긴다.

## 함정
- 한글 사용자 경로에서 실행하면 바로 꺼진다. 반드시 위 cmd로 실행한다.
