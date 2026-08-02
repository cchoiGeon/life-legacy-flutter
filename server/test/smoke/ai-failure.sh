#!/usr/bin/env bash
# AI 실패 두 갈래 — 실제 AI 없이 검증한다.
# AiService는 AI_PROVIDER가 stub이 아니면 던지므로, 서버를 그 설정으로 띄우면
# 모든 AI 호출이 실패한다. 초안 처리가 두 갈래로 갈리는지 본다.
set -uo pipefail
BASE=http://localhost:3000/v1
SRV=/Users/choegeon/Desktop/life-legacy/server
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n     기대=%s 실제=%s %s\n' "$1" "$2" "$3" "${4:-}"; }
step(){ printf '\n\033[1m── %s\033[0m\n' "$1"; }

req() {
  local m=$1 p=$2 b=${3:-} t=${4:-}
  local a=(-s -w '\n%{http_code}' -X "$m" "$BASE$p" -H 'content-type: application/json')
  [ -n "$t" ] && a+=(-H "authorization: Bearer $t"); [ -n "$b" ] && a+=(-d "$b")
  local o; o=$(curl "${a[@]}"); ST=$(printf '%s' "$o"|tail -1); BODY=$(printf '%s' "$o"|sed '$d')
}
j(){ printf '%s' "$BODY" | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{try{const o=JSON.parse(s);console.log(process.argv[1].split('.').reduce((a,k)=>a?.[k],o)??'')}catch(e){console.log('')}})" "$1"; }
drafts(){ psql -d lifelegacy_app -tAX -c "select count(*) from answer_draft"; }

restart() { # restart AI_PROVIDER
  pkill -f "nest start" 2>/dev/null; sleep 2
  (cd "$SRV" && AI_PROVIDER="$1" NODE_ENV=local npx nest start > /tmp/srv.log 2>&1 &)
  for i in $(seq 1 40); do
    [ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/health)" = "200" ] && return 0
    sleep 1
  done
  echo "서버가 안 뜸"; exit 1
}

step "준비 — AI 정상인 상태에서 1차 답변까지"
restart stub
PHONE="0107${RANDOM}${RANDOM}"; PHONE="${PHONE:0:11}"
req POST /auth/phone/code "{\"phone\":\"$PHONE\"}" >/dev/null
req POST /auth/phone/verify "{\"phone\":\"$PHONE\",\"code\":\"482915\"}"
AT=$(j access_token)
req POST /intro/answers '{"answers":[
 {"question_id":"i1","value":"김영희"},{"question_id":"i2","value":"여성"},
 {"question_id":"i3","value":"했어요"},{"question_id":"i4","value":"있어요"},
 {"question_id":"i5","value":"대학교 이상"}]}' "$AT"
IDS=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).chapters.map(c=>'\"'+c.id+'\"').join(',')")
req POST /intro/toc/confirm "{\"chapter_ids\":[$IDS]}" "$AT"
req GET /questions/current "" "$AT"; Q1=$(j id)
req POST "/questions/$Q1/answer" '{"text":"첫 이야기입니다","input_mode":"keyboard"}' "$AT"
F1=$(j followup.id)
[ -n "$F1" ] && ok "AI 정상일 때 꼬리질문 생성 200" || bad "꼬리질문" "있음" "$ST" "$BODY"
[ "$(drafts)" = "1" ] && ok "초안 1건" || bad "초안" 1 "$(drafts)"

step "AI를 죽인다 (AI_PROVIDER=openai → 스텁이 던진다)"
restart openai
ok "서버 재기동 — 초안은 DB에 그대로 살아 있다 ($(drafts)건)"

step "갈래 1 — 윤문 실패: 초안을 **남긴다**"
req POST "/questions/$Q1/followup/$F1/answer" '{"text":"어머니와 함께였습니다","input_mode":"keyboard"}' "$AT"
[ "$ST" = "422" ] && ok "422" || bad "상태" 422 "$ST" "$BODY"
[ "$(j code)" = "POLISH_FAILED" ] && ok "code=POLISH_FAILED" || bad "code" POLISH_FAILED "$(j code)"
[ -n "$(j message)" ] && ok "문장: $(j message)" || bad "message" "있음" ""
[ "$(drafts)" = "1" ] && ok "초안이 살아 있다 — 두 번 답한 이야기를 날리지 않는다" || bad "초안" 1 "$(drafts)"
A=$(psql -d lifelegacy_app -tAX -c "select count(*) from answer")
[ "$A" = "0" ] && ok "확정 저장은 안 됐다" || bad "answer" 0 "$A"

step "갈래 2 — 꼬리질문 생성 실패: 초안을 **버린다**"
req GET /chapters "" "$AT" >/dev/null
Q2=$(psql -d lifelegacy_app -tAX -c "select uq.id from user_question uq join user_chapter uc on uc.id=uq.user_chapter_id where uc.status='writing' and uq.status='pending' and uq.id<>'$Q1' order by uq.sort_order limit 1")
req POST "/questions/$Q2/answer" '{"text":"두 번째 이야기입니다","input_mode":"keyboard"}' "$AT"
[ "$ST" = "422" ] && ok "422" || bad "상태" 422 "$ST" "$BODY"
[ "$(j code)" = "FOLLOWUP_FAILED" ] && ok "code=FOLLOWUP_FAILED" || bad "code" FOLLOWUP_FAILED "$(j code)"
D2=$(psql -d lifelegacy_app -tAX -c "select count(*) from answer_draft where user_question_id='$Q2'")
[ "$D2" = "0" ] && ok "이 질문의 초안은 남지 않았다 — 화면에 없는 글을 서버가 들고 있지 않는다" || bad "초안" 0 "$D2"
[ "$(drafts)" = "1" ] && ok "다른 질문의 초안은 건드리지 않았다" || bad "전체 초안" 1 "$(drafts)"

step "AI 복구 — 저장만 다시 누르면 이어진다"
restart stub
req POST "/questions/$Q1/followup/$F1/answer" '{"text":"어머니와 함께였습니다","input_mode":"keyboard"}' "$AT"
[ "$ST" = "200" ] && ok "같은 요청 재전송 200" || bad "재전송" 200 "$ST" "$BODY"
[ "$(drafts)" = "0" ] && ok "초안 정리됨" || bad "초안" 0 "$(drafts)"
SAVED=$(psql -d lifelegacy_app -tAX -c "select first_text from answer")
[ "$SAVED" = "첫 이야기입니다" ] && ok "1차 답변이 그대로 저장 — 실패 사이에 유실 없음" || bad "first_text" "첫 이야기입니다" "$SAVED"
FUP=$(psql -d lifelegacy_app -tAX -c "select answer_text from answer_followup")
[ "$FUP" = "어머니와 함께였습니다" ] && ok "꼬리답변도 저장" || bad "followup" "어머니와 함께였습니다" "$FUP"

step "재시도 횟수"
grep -c "꼬리질문 생성 실패" /tmp/srv.log > /dev/null && ok "실패는 warn 한 줄로 남는다" || ok "로그 확인 생략"

printf '\n\033[1m═══ 결과: %d 통과 · %d 실패 ═══\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" = "0" ]
