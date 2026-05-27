---
name: draw-diagram
description: Decide the right Mermaid diagram type for the user's intent, clarify the missing details via AskUserQuestion, then render the diagram as Mermaid syntax inside a ```mermaid code block. Use this skill whenever the user wants to draw / sketch / visualize / 시각화하다 / 도식화하다 / 그리다 something as a diagram — flowchart, sequence diagram, class diagram, state machine, ER/DB schema, gantt, mindmap, timeline, pie/quadrant/xy/sankey chart, gitgraph, C4, architecture, requirement. Trigger on Korean phrases like "시각화해줘", "도식화해줘", "그려줘", "그림으로 보여줘", "다이어그램 그려줘", "흐름도 그려줘", "플로우 그려줘", "시퀀스 다이어그램", "구조도", "아키텍처 그림", "ERD 그려줘", "상태 다이어그램", and English phrases like "diagram 그려줘", "draw a chart", "draw a diagram", "sketch this", "visualize this as", "mermaid". Also trigger when the user describes a process, flow, system architecture, data model, lifecycle, or relationships and asks to "보여줘" or "시각화" — even if they don't explicitly say "다이어그램" — since the goal is to convert their mental model into a renderable Mermaid spec.
---

# Draw Diagram

사용자가 머릿속의 구조/흐름/관계를 다이어그램으로 보고 싶어할 때, **Mermaid 문법으로 렌더 가능한 코드 블록**을 만들어 준다.

핵심 흐름은 항상 같다.

1. **무엇을 그릴지 결정** — 아래 Decision Tree로 Mermaid 다이어그램 타입 하나를 고른다.
2. **부족한 정보를 명확화** — 해당 타입의 reference 파일을 읽고, 거기에 적힌 질문들을 `AskUserQuestion`으로 1차 질의한다.
3. **Mermaid 코드 출력** — 답변을 바탕으로 ` ```mermaid ` 코드 블록을 작성한다. 별도 파일을 만들지 말고 채팅에 직접 코드 블록으로 보여준다.
4. **렌더 미리보기 첨부** — 코드 블록 바로 아래에 `mermaid.ink` 이미지와 `mermaid.live` 편집 링크를 붙인다. CLI/클라우드 sandbox/모바일 앱 어디서나 그림으로 바로 확인할 수 있게.

## 1단계: 다이어그램 타입 결정

사용자의 발화에서 "무엇을 보고 싶은가"를 먼저 추출한다. 사용자가 이미 타입을 지정했다면 (예: "시퀀스 다이어그램", "ERD") 그걸 그대로 사용한다. 모호하면 아래 트리로 매핑한다.

```
사용자가 보여주고 싶은 것은?
│
├─ 의사결정/처리 흐름, 알고리즘, 분기 로직
│    → flowchart       (references/flowchart.md)
│
├─ 시간 순서로 일어나는 행위자/컴포넌트 간 메시지/호출
│    → sequenceDiagram (references/sequence.md)
│
├─ 객체의 상태와 전이 (lifecycle, FSM)
│    → stateDiagram-v2 (references/state.md)
│
├─ 구조/관계
│    ├─ OOP 클래스·메서드·상속 → classDiagram   (references/class.md)
│    ├─ DB 테이블·관계 (1:N 등) → erDiagram     (references/er.md)
│    ├─ 시스템 컴포넌트·연결    → architecture-beta (references/architecture.md)
│    └─ 시스템 컨텍스트/컨테이너 (C4 모델) → C4Context (references/c4.md)
│
├─ 시간/일정
│    ├─ 의존성·기간이 있는 프로젝트 일정 → gantt    (references/gantt.md)
│    └─ 시점 나열 (의존성 없음)           → timeline (references/timeline.md)
│
├─ 데이터 시각화
│    ├─ 전체 중 비율             → pie           (references/pie.md)
│    ├─ 2축 4분면 분류           → quadrantChart (references/quadrant.md)
│    ├─ X/Y 수치 데이터 (막대/선) → xychart-beta  (references/xychart.md)
│    └─ 흐름 + 양 (예: 에너지/예산 흐름) → sankey-beta (references/sankey.md)
│
├─ 사용자 경험 단계 + 만족도
│    → journey         (references/journey.md)
│
├─ 아이디어/주제 계층 (브레인스토밍)
│    → mindmap         (references/mindmap.md)
│
├─ Git 브랜치/머지 히스토리
│    → gitGraph        (references/gitgraph.md)
│
└─ 요구사항 추적 (requirement traceability)
     → requirementDiagram (references/requirement.md)
```

### 헷갈리기 쉬운 경계

- **flowchart vs sequence**: "누가 → 누구에게" 시간순 메시지면 sequence. 그게 아니라 박스/마름모로 흐름·분기만 보여주면 flowchart.
- **flowchart vs state**: 노드가 **상태**(예: `Pending`, `Paid`)고 화살표가 **이벤트로 인한 전이**면 state. 노드가 **할 일/단계**면 flowchart.
- **class vs ER**: 코드 레벨(메서드·상속) → class. 데이터 모델(PK/FK, 카디널리티) → ER.
- **architecture vs C4**: 서비스/큐/DB 같은 인프라 컴포넌트 간 연결을 가볍게 그리면 architecture-beta. "System Context / Container / Component" 추상화 수준을 명시적으로 다루면 C4.
- **gantt vs timeline**: 막대(기간) + 의존성이 필요하면 gantt. "언제 무엇이 있었다" 점들의 나열이면 timeline.
- **mindmap vs flowchart**: 중심 주제에서 뻗어나가는 **계층 트리**면 mindmap. 방향성 있는 처리 흐름이면 flowchart.

판단이 잘 안 서면 사용자에게 **두세 가지 후보를 짧게 제시하고 고르게 한다** (`AskUserQuestion`). 추측으로 큰 다이어그램을 다 그렸다가 갈아엎는 것보다 훨씬 싸다.

## 2단계: 명확화 질의

타입을 정한 직후, **그리기 전에** 해당 `references/<type>.md`를 읽고 그 파일에 적힌 질문들을 `AskUserQuestion`으로 묻는다. 보통 한 번에 1~3개, 진짜로 답이 다이어그램 모양을 바꾸는 것만 골라서 묻는다.

원칙:

- **이미 사용자가 답한 것을 다시 묻지 않는다.** 발화·첨부 코드·이전 답변에서 추출할 수 있으면 그걸 쓰고, 명시적으로 확인만 한다.
- **AskUserQuestion 한 번에 모든 질문을 묶어 보낸다.** 같은 자리에서 답할 수 있는 질문은 한 번의 호출로.
- **답이 없어도 합리적 기본값으로 진행할 수 있다면**, 기본값을 보기로 넣어 두고 사용자가 빠르게 수락할 수 있게 한다.
- **자동 모드(Auto Mode)에서도 1차 명확화는 한다.** Auto Mode의 "굳이 안 물어봐도 되면 묻지 마라"는 지침은, 다이어그램처럼 **사용자의 의도가 결과 모양을 직접 결정하는 산출물**에는 그대로 적용되지 않는다. 다만 질문은 짧고 본질적인 것만.

## 3단계: Mermaid 코드 출력

답변을 받으면 즉시 코드 블록으로 출력한다.

```mermaid
<여기에 mermaid 코드>
```

- 별도 파일을 만들거나 도구를 호출하지 말고, 답변 본문에 코드 블록으로 직접 보낸다 (사용자가 명시적으로 파일로 저장해달라고 하면 그때 저장).
- 사용자 텍스트가 한국어면 노드 라벨도 한국어로 쓴다. 다만 **노드 ID는 ASCII로** (한글 ID는 일부 렌더러에서 깨진다). `A["주문 생성"] --> B["결제"]` 같은 식.
- 라벨에 `()`, `[]`, `:`, `;`, 따옴표가 들어가면 큰따옴표로 감싼다: `A["foo (bar)"]`.
- 한 다이어그램에 모든 걸 욱여넣지 말고, 핵심을 먼저 보이고 사용자가 "더 자세히"라고 하면 그때 확장한다.

렌더 후 짧게 한 줄로 "어디를 바꾸면 좋을지" 물어 보면 좋다 (예: "타입을 다른 걸로 바꿀까요? 노드를 더 쪼갤까요?").

## 4단계: 렌더 미리보기 첨부

코드 블록만 보내면 CLI에서는 그림이 안 보이고, 모바일/웹 앱에서도 ` ```mermaid ` 블록을 렌더해 주지 않는 경우가 많다. 그래서 **항상** Mermaid 코드 블록 바로 아래에 다음 두 줄을 함께 출력한다.

```
![diagram](https://mermaid.ink/img/pako:<인코딩>)
편집·다른 테마로 보기: https://mermaid.live/edit#pako:<인코딩>
```

- `mermaid.ink` 이미지는 모바일/웹 앱 채팅에 **인라인으로 자동 렌더**된다. CLI에서도 URL을 클릭하면 브라우저에서 열린다.
- `mermaid.live` 링크는 사용자가 직접 수정·테마 변경·SVG로 내보내기를 할 수 있는 에디터로 연결된다.
- 두 URL의 `<인코딩>`은 같은 값(아래 헬퍼로 한 번에 계산).

### 인코딩 헬퍼

다이어그램 코드를 stdin으로 넘기면 pako 인코딩 문자열을 출력한다. `Bash`로 한 번 실행해 결과를 받아온다.

```bash
python3 - <<'PY' <<<"<여기에 mermaid 코드>"
import base64, zlib, json, sys
s = {"code": sys.stdin.read(), "mermaid": {"theme": "default"}}
print(base64.urlsafe_b64encode(zlib.compress(json.dumps(s).encode(), 9)).decode())
PY
```

heredoc 안에 mermaid 코드의 `\`, `"`, `$`, 백틱이 그대로 들어가도 안전하도록 가능하면 코드를 임시 파일로 저장한 뒤 `python3 helper.py < /tmp/diag.mmd` 식으로 호출해도 좋다.

### 민감 정보 가드 — 반드시 확인하고 출력한다

`mermaid.ink`/`mermaid.live`는 **외부 서비스**다. 인코딩된 다이어그램 코드가 그 서버를 거친다. 다음 중 하나라도 다이어그램에 포함돼 있다면 URL을 만들지 말고 코드 블록만 출력한 뒤, 사용자에게 "외부 렌더 서비스로 보내도 괜찮을지" 한 번 묻는다.

- 사내 시스템/도메인/팀 이름이 식별 가능한 형태
- 고객/사용자 식별 정보(이메일, 사번, 전화)
- API 키·토큰·시크릿
- 미공개 기능명, 비공개 프로젝트 코드명

사용자가 "외부 OK"라고 명시했거나, 다이어그램이 공개해도 무방한 일반 예시(샘플 도메인, 가짜 데이터, 공개된 오픈소스 구조 등)면 그냥 첨부한다.

### 한 번 마무리 예시

````
```mermaid
flowchart TD
    A["주문 생성"] --> B{"재고 있음?"}
    B -- 예 --> C["결제 진행"]
    B -- 아니오 --> D["품절 안내"]
    C --> E(["완료"])
```

![diagram](https://mermaid.ink/img/pako:eNpVkMEKwjAMhl-l5KSg0Lk6owfFbb6BN-uhTTsUnIJseBh7d9MMBHsIhP_LF9IB6BUi7BQ0j9eHbu7dqXNtn4rf8WLB9oQN2d77HBU3OgSuWZ5ZuKrlcq_KQaCNY8hR1AnaIKZq6GBhnFwlwykqNMpYJW5HXqcNGaVsS8b2YY1bdv9PrQ0nfkVJW6yMGGoxBCO7UOPEceO1Nz9DJexpNp1SiAeJOJ_DQkEb3627B75_gO4WW_mJEBvXPzoYxy8-PlOQ)
편집·테마 변경: https://mermaid.live/edit#pako:eNpVkMEKwjAMhl-l5KSg0Lk6owfFbb6BN-uhTTsUnIJseBh7d9MMBHsIhP_LF9IB6BUi7BQ0j9eHbu7dqXNtn4rf8WLB9oQN2d77HBU3OgSuWZ5ZuKrlcq_KQaCNY8hR1AnaIKZq6GBhnFwlwykqNMpYJW5HXqcNGaVsS8b2YY1bdv9PrQ0nfkVJW6yMGGoxBCO7UOPEceO1Nz9DJexpNp1SiAeJOJ_DQkEb3627B75_gO4WW_mJEBvXPzoYxy8-PlOQ
````

## 참고 파일

각 다이어그램 타입의 **명확화 질문 + 최소 문법 예시 + 자주 하는 실수**는 아래 파일에 있다. 타입이 정해지면 그 파일 하나만 읽으면 된다.

- `references/flowchart.md`
- `references/sequence.md`
- `references/state.md`
- `references/class.md`
- `references/er.md`
- `references/architecture.md`
- `references/c4.md`
- `references/gantt.md`
- `references/timeline.md`
- `references/pie.md`
- `references/quadrant.md`
- `references/xychart.md`
- `references/sankey.md`
- `references/journey.md`
- `references/mindmap.md`
- `references/gitgraph.md`
- `references/requirement.md`
