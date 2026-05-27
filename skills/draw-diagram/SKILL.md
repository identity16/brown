---
name: draw-diagram
description: Decide the right Mermaid diagram type for the user's intent, clarify the missing details via AskUserQuestion, then render the diagram as Mermaid syntax inside a ```mermaid code block. Use whenever the user wants to draw, sketch, render, or visualize something as a diagram — flowchart, sequence diagram, class diagram, state machine, ER/DB schema, gantt, mindmap, timeline, pie/quadrant/xy/sankey chart, gitgraph, C4, architecture, requirement. Triggers on phrases like "diagram 그려줘", "flow 그려줘", "시퀀스 다이어그램", "구조도", "아키텍처 그림", "draw a chart", "visualize this as", "mermaid".
---

# Draw Diagram

사용자가 머릿속의 구조/흐름/관계를 다이어그램으로 보고 싶어할 때, **Mermaid 문법으로 렌더 가능한 코드 블록**을 만들어 준다.

핵심 흐름은 항상 같다.

1. **무엇을 그릴지 결정** — 아래 Decision Tree로 Mermaid 다이어그램 타입 하나를 고른다.
2. **부족한 정보를 명확화** — 해당 타입의 reference 파일을 읽고, 거기에 적힌 질문들을 `AskUserQuestion`으로 1차 질의한다.
3. **Mermaid 코드 출력** — 답변을 바탕으로 ` ```mermaid ` 코드 블록을 작성한다. 별도 파일을 만들지 말고 채팅에 직접 코드 블록으로 보여준다.

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
