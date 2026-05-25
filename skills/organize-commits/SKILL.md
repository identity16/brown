---
name: organize-commits
description: Reorganize the current branch's work into a clean, reviewer-friendly sequence of bisectable commits. Use when the user asks to clean up commits, split a messy WIP into logical commits, prepare a branch for review/PR, organize changes into bisectable history, or rewrite history so each commit builds and passes tests on its own. Triggers on phrases like "organize commits", "bisectable commit", "정리해줘", "리뷰어 친화적으로", "커밋 쪼개줘", "split this commit", "clean up history".
---

# Organize Commits

브랜치의 작업물을 **리뷰어가 한 커밋씩 따라 읽을 수 있고**, **각 커밋이 독립적으로 빌드/테스트를 통과하는** 시퀀스로 재구성한다.

## 원칙

각 커밋은 다음을 모두 만족해야 한다.

1. **하나의 논리적 변경만 담는다.** 리팩터링과 동작 변경을 섞지 않는다. 포매팅·이름 변경 같은 기계적(mechanical) 변경은 별도 커밋으로 분리한다.
2. **그 시점만으로 빌드/테스트가 통과한다.** "다음 커밋에서 고침" 같은 부채를 남기지 않는다 → `git bisect`가 의미를 가진다.
3. **메시지는 WHY를 설명한다.** WHAT은 diff가 이미 보여준다. 제약 조건, 대안을 버린 이유, 숨은 invariant를 적는다.
4. **순서가 의미를 가진다.** 일반적으로 `사전 정리/리팩터 → 인프라/추가 → 새 동작 → 호출부 전환 → 죽은 코드 제거 → 테스트/문서` 순. 뒤 커밋이 앞 커밋의 변경을 되돌리면 안 된다.
5. **작게 유지한다.** 한 자리에서 읽을 수 있는 크기. 너무 크면 거의 항상 더 쪼갤 수 있다.

## 절차

### 1. 현재 상태 파악

병렬로 실행한다.

```
git status
git log --oneline @{upstream}..HEAD   # upstream 없으면 main/master 기준
git diff --stat <base>...HEAD
git diff <base>...HEAD                # 전체 diff 한 번 훑기
```

`<base>`는 보통 `origin/main` 또는 `main`. 모르면 사용자에게 확인.

### 2. 변경을 논리 단위로 그룹핑

전체 diff를 읽고 "리뷰어에게 어떻게 설명할 것인가" 관점에서 묶는다. 예:

- 사전 리팩터 (동작 변화 없음)
- 새 모듈/타입/헬퍼 추가 (아직 아무도 호출 안 함)
- 새 동작 구현
- 호출부 전환 (구→신)
- 죽은 코드 제거
- 테스트 / 문서

묶음을 사용자에게 짧게 보여주고 합의를 받는다. (커밋이 3개를 넘으면 거의 항상 보여주는 게 낫다.)

### 3. 안전망 만들기

재구성 전에 백업 브랜치를 만든다.

```
git branch backup/<current>-$(date +%s)
```

작업 트리에 untracked/uncommitted가 있으면 먼저 stash 또는 커밋. 사용자에게 알린다.

### 4. 재구성 방법 선택

상황에 맞는 방법을 사용자에게 제안한다.

- **커밋이 1개거나 working tree만 있는 경우**: `git reset` 후 hunk 단위로 다시 커밋
  ```
  git reset <base>            # 또는 reset --soft HEAD~N
  git add -p                  # 그룹별로 hunk 선택
  git commit -m "..."
  ```
- **여러 커밋을 재배열/합치기**: `git rebase -i <base>` — **단, `-i` 플래그는 대화형이라 이 환경에서 직접 실행할 수 없다.** 사용자에게 명령을 알려주고 직접 실행하도록 안내하거나, `git rebase --onto` + cherry-pick 조합으로 비대화형 처리.
- **파일별로 명확히 갈리는 경우**: `git add <file>` 후 커밋 반복.
- **한 파일 안에서 갈리는 경우**: `git add -p` (hunk 분할은 `s`, 라인 단위는 `e`).

### 5. 각 커밋 검증

이게 "bisectable"의 핵심이다. 각 커밋을 만들 때마다:

```
<build 명령>     # 프로젝트별. 없으면 type check / lint라도.
<test 명령>     # 빠른 단위 테스트라도.
```

실패하면 그 커밋을 수정한다 (`git commit --amend` 또는 fixup + autosquash). **절대 "다음 커밋에서 고친다"고 넘어가지 않는다.**

전체가 끝난 뒤 한 번 더 확인:

```
git rebase <base> --exec '<build>; <test>'
```

이게 통과하면 모든 커밋이 개별적으로 통과한다는 뜻.

### 6. 커밋 메시지

제목 줄(50자 내외) + 빈 줄 + 본문(72자 wrap). 본문은:

- **왜** 이 변경이 필요한가
- 고려했지만 버린 대안 (있으면)
- 리뷰어가 놓치기 쉬운 제약/invariant
- 이 커밋이 시리즈의 어디쯤인지 (예: "후속 커밋에서 호출부 전환")

리포의 기존 스타일(`git log`)을 먼저 본다 — conventional commits 쓰는 곳이면 따른다.

### 7. 푸시

이미 푸시된 브랜치라면 force-push가 필요하다. **반드시 사용자 승인을 받고**, `--force-with-lease`를 사용한다. main/master에는 절대 force-push 안 한다.

```
git push --force-with-lease -u origin <branch>
```

## 안전 수칙

- **백업 브랜치 없이 history 재작성 금지.**
- `rebase -i`는 대화형이므로 이 환경에서 직접 호출하지 않는다 — 사용자에게 명령을 안내하거나 비대화형 대안을 쓴다.
- `--no-verify`, `git push -f` (lease 없는) 는 사용자가 명시적으로 요청하지 않는 한 쓰지 않는다.
- 빌드/테스트 명령을 모르면 `CLAUDE.md`, `package.json`, `Makefile`, `README` 등에서 찾고, 없으면 사용자에게 묻는다.
- 한 커밋이 너무 커지면 멈추고 더 쪼갤 수 있는지 사용자와 상의한다.

## 안티패턴

- "WIP", "fix", "address review" 같은 의미 없는 메시지를 그대로 남기는 것
- 같은 파일을 두 번 만지면서 두 번째 커밋이 첫 번째를 부분적으로 되돌리는 것
- 리팩터와 동작 변경을 한 커밋에 섞는 것
- 테스트만 있는 커밋을 구현 *앞*에 두는 것 (그 커밋에서 테스트가 실패함 → bisect 깨짐)
- 마지막에 한 번 `npm test` 돌리고 "통과한다"고 보고하는 것 — 각 커밋이 통과해야 의미가 있다
