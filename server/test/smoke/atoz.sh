#!/usr/bin/env bash
# Life-Legacy Server — A to Z HTTP 스모크 (AI 실제 제공자·카카오 제외)
# 실패하면 그 자리에서 멈춘다.
set -uo pipefail

BASE=http://localhost:3000/v1
PHONE="0109${RANDOM}${RANDOM}"; PHONE="${PHONE:0:11}"
PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ❌ %s\n     기대=%s 실제=%s\n     본문=%s\n' "$1" "$2" "$3" "${4:-}"; }
step() { printf '\n\033[1m── %s\033[0m\n' "$1"; }

# req METHOD PATH [BODY] [TOKEN] -> STATUS를 $ST, 본문을 $BODY에 넣는다
req() {
  local m=$1 p=$2 b=${3:-} t=${4:-}
  local args=(-s -w '\n%{http_code}' -X "$m" "$BASE$p" -H 'content-type: application/json')
  [ -n "$t" ] && args+=(-H "authorization: Bearer $t")
  [ -n "$b" ] && args+=(-d "$b")
  local out; out=$(curl "${args[@]}")
  ST=$(printf '%s' "$out" | tail -1)
  BODY=$(printf '%s' "$out" | sed '$d')
}

# expect NAME EXPECTED_STATUS
expect() { [ "$ST" = "$2" ] && ok "$1" || bad "$1" "$2" "$ST" "$BODY"; }

j() { printf '%s' "$BODY" | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{try{const o=JSON.parse(s);const v=process.argv[1].split('.').reduce((a,k)=>a===null||a===undefined?a:a[/^\d+$/.test(k)?+k:k],o);console.log(v===undefined||v===null?'':v)}catch(e){console.log('')}})" "$1"; }

# ══════════════════════════════════════════════════════════
step "0. 헬스체크 · 프리픽스"
S=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/health)
[ "$S" = "200" ] && ok "GET /health 200 (프리픽스 제외)" || bad "GET /health" 200 "$S"

step "1. 인증 — 인증번호 발급"
req POST /auth/phone/code "{\"phone\":\"$PHONE\"}"
expect "POST /auth/phone/code 200" 200
[ "$(j expires_in)" = "180" ] && ok "expires_in=180" || bad "expires_in" 180 "$(j expires_in)"
[ "$(j resend_after)" = "30" ] && ok "resend_after=30" || bad "resend_after" 30 "$(j resend_after)"

req POST /auth/phone/code "{\"phone\":\"$PHONE\"}"
R2=$(j resend_after)
[ -n "$R2" ] && [ "$R2" -le 30 ] && ok "재발송 대기 중이면 새로 만들지 않고 남은 시간만 준다 (resend_after=$R2)" \
  || bad "재발송 대기" "<=30" "$R2"

step "2. 인증 — 검증 실패 갈래"
req POST /auth/phone/verify "{\"phone\":\"$PHONE\",\"code\":\"000000\"}"
expect "틀린 인증번호 → 401" 401
[ "$(j code)" = "INVALID_CODE" ] && ok "code=INVALID_CODE" || bad "code" INVALID_CODE "$(j code)"
[ -n "$(j message)" ] && ok "message가 한국어 문장으로 온다: $(j message)" || bad "message" "비어있지 않음" ""

req POST /auth/phone/verify "{\"phone\":\"$PHONE\"}"
expect "code 누락 → 400" 400
[ "$(j code)" = "INVALID_REQUEST" ] && ok "ValidationPipe 상세 대신 공통 문구" || bad "code" INVALID_REQUEST "$(j code)"

req POST /auth/phone/verify "{\"phone\":\"$PHONE\",\"code\":\"482915\",\"hack\":1}"
expect "화이트리스트 밖 필드 → 400" 400

step "3. 인증 — 가입 겸 로그인"
req POST /auth/phone/verify "{\"phone\":\"$PHONE\",\"code\":\"482915\"}"
expect "POST /auth/phone/verify 200" 200
AT=$(j access_token); RT=$(j refresh_token)
[ -n "$AT" ] && ok "access_token 발급" || bad "access_token" "비어있지 않음" ""
[ -n "$RT" ] && ok "refresh_token 발급" || bad "refresh_token" "비어있지 않음" ""
[ "$(j needs_intro)" = "true" ] && ok "신규 사용자 needs_intro=true" || bad "needs_intro" true "$(j needs_intro)"
[ "$(j user.phone)" = "$PHONE" ] && ok "user.phone 일치" || bad "user.phone" "$PHONE" "$(j user.phone)"

step "4. 인가"
req GET /users/me
expect "토큰 없이 → 401" 401
[ "$(j code)" = "UNAUTHORIZED" ] && ok "code=UNAUTHORIZED (TOKEN_EXPIRED 아님)" || bad "code" UNAUTHORIZED "$(j code)"
req GET /users/me "" "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ4In0.zzz"
expect "위조 토큰 → 401" 401
req GET /users/me "" "$AT"
expect "GET /users/me 200" 200

step "5. 자기소개 — 순서 강제"
req POST /intro/toc/confirm '{"chapter_ids":[]}' "$AT"
expect "자기소개 전 목차 확정 → 400 (INTRO_REQUIRED 계열)" 400

req GET /intro/questions "" "$AT"
expect "GET /intro/questions 200" 200
QN=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).items.length")
[ "$QN" = "5" ] && ok "문항 5개" || bad "문항 수" 5 "$QN"
CH=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).items.find(q=>q.id==='i5').choices.join('/')")
[ "$CH" = "초등학교/중학교/고등학교/대학교 이상" ] && ok "i5 선택지 4개가 실려 온다" || bad "i5 choices" "4개" "$CH"

req POST /intro/answers '{"answers":[{"question_id":"i1","value":"김영희"},{"question_id":"i2","value":"여성"}]}' "$AT"
expect "5문항 다 안 오면 → 400" 400

step "6. 자기소개 — 케이스 판정 (대학O·결혼O·자녀O = 10장)"
req POST /intro/answers '{"answers":[
 {"question_id":"i1","value":"김영희"},{"question_id":"i2","value":"여성"},
 {"question_id":"i3","value":"했어요"},{"question_id":"i4","value":"있어요"},
 {"question_id":"i5","value":"대학교 이상"}]}' "$AT"
expect "POST /intro/answers 200" 200
CK=$(j case_key)
NC=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).chapters.length")
[ "$NC" = "10" ] && ok "10장 생성 (case_key=$CK)" || bad "장 수" 10 "$NC"
ST1=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).chapters[0].status")
ST2=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).chapters[1].status")
[ "$ST1" = "writing" ] && ok "1장만 writing" || bad "1장 status" writing "$ST1"
[ "$ST2" = "locked" ] && ok "2장은 locked" || bad "2장 status" locked "$ST2"
IDS=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).chapters.map(c=>c.id).join(' ')")
read -r -a CID <<< "$IDS"

step "7. 자기소개 — 재제출로 축 뒤집기 (대학X = 9장)"
req POST /intro/answers '{"answers":[
 {"question_id":"i1","value":"김영희"},{"question_id":"i2","value":"여성"},
 {"question_id":"i3","value":"했어요"},{"question_id":"i4","value":"있어요"},
 {"question_id":"i5","value":"고등학교"}]}' "$AT"
NC2=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).chapters.length")
HAS=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).chapters.some(c=>c.title.includes('대학'))")
[ "$NC2" = "9" ] && ok "고등학교 → 9장으로 줄어듦" || bad "장 수" 9 "$NC2"
[ "$HAS" = "false" ] && ok "대학생활 장이 빠짐 (옛 목차가 남지 않는다)" || bad "대학 장 포함" false "$HAS"

step "8. 자기소개 — 다시 대학으로 돌리고 목차 확정 (순서 뒤집어서)"
req POST /intro/answers '{"answers":[
 {"question_id":"i1","value":"김영희"},{"question_id":"i2","value":"여성"},
 {"question_id":"i3","value":"했어요"},{"question_id":"i4","value":"있어요"},
 {"question_id":"i5","value":"대학교 이상"}]}' "$AT"
IDS=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).chapters.map(c=>c.id).join(' ')")
read -r -a CID <<< "$IDS"

req POST /intro/toc/confirm "{\"chapter_ids\":[\"${CID[0]}\"]}" "$AT"
expect "일부만 보내면 → 400" 400

# 1번과 2번을 맞바꿔 보낸다
REORDER=$(printf '"%s","%s"' "${CID[1]}" "${CID[0]}")
for i in $(seq 2 9); do REORDER="$REORDER,\"${CID[$i]}\""; done
req POST /intro/toc/confirm "{\"chapter_ids\":[$REORDER]}" "$AT"
expect "POST /intro/toc/confirm 204 (1·2장 맞바꿈)" 204

req POST /intro/toc/confirm "{\"chapter_ids\":[$REORDER]}" "$AT"
expect "두 번 확정 → 409" 409

req GET /chapters "" "$AT"
FIRST=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).items[0].title")
[ "$FIRST" = "가족환경과 성장환경" ] && ok "sortOrder 재배열 반영 (1장=$FIRST)" || bad "1장 제목" "가족환경과 성장환경" "$FIRST"
NQ=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).items[0].next_question_text||''")
[ -n "$NQ" ] && ok "writing 장에는 next_question_text가 붙는다" || bad "next_question_text" "있음" ""
NQ2=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).items[1].next_question_text")
[ "$NQ2" = "null" ] && ok "locked 장에는 안 붙는다" || bad "locked next_question_text" null "$NQ2"

req GET /users/me "" "$AT"
[ "$(j name)" = "김영희" ] && ok "i1 값이 app_user.name으로 반영" || bad "name" "김영희" "$(j name)"

req GET /intro/profile "" "$AT"
expect "GET /intro/profile 200" 200
EN=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).entries.map(e=>e.label+'='+e.value).join(', ')")
[ "$EN" = "성별=여성, 결혼=했어요, 자녀=있어요, 학력=대학교 이상" ] \
  && ok "라벨·값을 서버가 짝지어 준다 ($EN)" || bad "entries" "성별/결혼/자녀/학력" "$EN"
case "$EN" in *김영희*) bad "성함 제외" "없음" "포함됨" ;; *) ok "성함은 목록에 넣지 않는다" ;; esac

step "9. 홈 · 현재 질문"
req GET /home "" "$AT"
expect "GET /home 200" 200
TQ=$(j today_question); TQID=$(j today_question_id)
[ -n "$TQ" ] && ok "오늘의 질문: ${TQ:0:30}…" || bad "today_question" "있음" ""
[ "$(j progress)" = "0" ] && ok "progress=0" || bad "progress" 0 "$(j progress)"
[ "$(j chapter_total)" = "10" ] && ok "chapter_total=10" || bad "chapter_total" 10 "$(j chapter_total)"
RQ0=$(j remaining_questions)
ok "남은 질문 ${RQ0}개"

req GET /questions/current "" "$AT"
expect "GET /questions/current 200" 200
QID=$(j id)
[ "$QID" = "$TQID" ] && ok "홈과 current가 같은 질문을 가리킨다" || bad "질문 id" "$TQID" "$QID"

req GET "/questions/$QID" "" "$AT"
expect "GET /questions/:id 200" 200

step "10. 소유·잠금 검사"
req GET /questions/00000000-0000-0000-0000-000000000000 "" "$AT"
expect "없는 질문 → 404" 404
LOCKED=$(psql -d lifelegacy_app -tAX -c "select uq.id from user_question uq join user_chapter uc on uc.id=uq.user_chapter_id where uc.status='locked' limit 1")
req POST "/questions/$LOCKED/answer" '{"text":"미리 답해보기","input_mode":"keyboard"}' "$AT"
expect "잠긴 장의 질문에 답하면 → 409" 409
[ "$(j code)" = "CHAPTER_LOCKED" ] && ok "code=CHAPTER_LOCKED" || bad "code" CHAPTER_LOCKED "$(j code)"

step "11. 질문 문구 수정"
req PATCH "/questions/$QID" '{"text":"제가 바꾼 질문입니다"}' "$AT"
expect "PATCH /questions/:id 200" 200
[ "$(j text)" = "제가 바꾼 질문입니다" ] && ok "문구 반영" || bad "text" "제가 바꾼 질문입니다" "$(j text)"
req GET "/questions/$QID" "" "$AT"
[ "$(j text)" = "제가 바꾼 질문입니다" ] && ok "다시 읽어도 유지" || bad "재조회 text" "제가 바꾼 질문입니다" "$(j text)"

step "12. 작성 — 1차 답변 → 꼬리질문"
req POST "/questions/$QID/answer" '{"text":"저는 해남에서 태어났습니다","input_mode":"voice","spoken_seconds":42}' "$AT"
expect "POST /questions/:id/answer 200" 200
FID=$(j followup.id); FTXT=$(j followup.text)
[ -n "$FID" ] && ok "followup.id 발급" || bad "followup.id" "있음" ""
[ -n "$FTXT" ] && ok "꼬리질문 생성됨" || bad "followup.text" "있음" ""
D=$(psql -d lifelegacy_app -tAX -c "select count(*) from answer_draft")
[ "$D" = "1" ] && ok "초안 1건 보관 (아직 확정 아님)" || bad "초안 수" 1 "$D"
A=$(psql -d lifelegacy_app -tAX -c "select count(*) from answer")
[ "$A" = "0" ] && ok "answer는 아직 0건" || bad "answer 수" 0 "$A"

req POST "/questions/$QID/answer" '{"text":"다시 답합니다","input_mode":"keyboard"}' "$AT"
expect "1차 답변 다시 보내기 200 (초안 덮어쓰기)" 200
FID2=$(j followup.id)
D=$(psql -d lifelegacy_app -tAX -c "select count(*) from answer_draft")
[ "$D" = "1" ] && ok "초안은 질문당 1건으로 유지" || bad "초안 수" 1 "$D"

req POST "/questions/$QID/followup/$FID/answer" '{"text":"옛 followup id로","input_mode":"keyboard"}' "$AT"
expect "옛 followup id로 저장 → 404" 404

step "13. 작성 — 꼬리답변으로 확정"
req POST "/questions/$QID/followup/$FID2/answer" '{"text":"어머니와 형이 함께 있었습니다","input_mode":"keyboard"}' "$AT"
expect "POST /questions/:id/followup/:fid/answer 200" 200
[ -n "$(j next_question.id)" ] && ok "다음 질문 반환: $(j next_question.text | cut -c1-28)…" || bad "next_question" "있음" ""
[ "$(j chapter_completed)" = "false" ] && ok "chapter_completed=false" || bad "chapter_completed" false "$(j chapter_completed)"
D=$(psql -d lifelegacy_app -tAX -c "select count(*) from answer_draft")
[ "$D" = "0" ] && ok "초안 정리됨" || bad "초안 수" 0 "$D"
RAW=$(psql -d lifelegacy_app -tAX -c "select first_text from answer limit 1")
[ "$RAW" = "다시 답합니다" ] && ok "저장된 원문이 마지막 1차 답변과 일치" || bad "first_text" "다시 답합니다" "$RAW"
MODE=$(psql -d lifelegacy_app -tAX -c "select first_input_mode||'/'||coalesce(first_spoken_seconds::text,'NULL') from answer limit 1")
[ "$MODE" = "keyboard/NULL" ] && ok "keyboard면 spoken_seconds NULL" || bad "input_mode/spoken" "keyboard/NULL" "$MODE"

req POST "/questions/$QID/answer" '{"text":"또 답하기","input_mode":"keyboard"}' "$AT"
expect "이미 답한 질문 → 409" 409
[ "$(j code)" = "ALREADY_ANSWERED" ] && ok "code=ALREADY_ANSWERED" || bad "code" ALREADY_ANSWERED "$(j code)"
req PATCH "/questions/$QID" '{"text":"답한 뒤 문구 수정"}' "$AT"
expect "답한 뒤 문구 수정 → 409" 409

step "14. 건너뛰기 + 장 완주 → 다음 장 잠금 해제"
CNT=$(psql -d lifelegacy_app -tAX -c "select question_count from user_chapter where sort_order=1")
for n in $(seq 2 "$CNT"); do
  req GET /questions/current "" "$AT"; Q=$(j id)
  if [ "$n" = "2" ]; then
    req POST "/questions/$Q/skip" "" "$AT"
    [ "$ST" = "200" ] && ok "질문 $n 건너뛰기 200" || bad "skip" 200 "$ST" "$BODY"
  else
    req POST "/questions/$Q/answer" "{\"text\":\"${n}번째 이야기입니다\",\"input_mode\":\"voice\",\"spoken_seconds\":3$n}" "$AT"
    F=$(j followup.id)
    req POST "/questions/$Q/followup/$F/answer" "{\"text\":\"${n}번째 이어서 답합니다\",\"input_mode\":\"keyboard\"}" "$AT"
    [ "$ST" = "200" ] || bad "질문 $n 저장" 200 "$ST" "$BODY"
  fi
done
[ "$(j chapter_completed)" = "true" ] && ok "마지막 질문에서 chapter_completed=true" || bad "chapter_completed" true "$(j chapter_completed)"
S1=$(psql -d lifelegacy_app -tAX -c "select status from user_chapter where sort_order=1")
S2=$(psql -d lifelegacy_app -tAX -c "select status from user_chapter where sort_order=2")
S3=$(psql -d lifelegacy_app -tAX -c "select status from user_chapter where sort_order=3")
[ "$S1" = "done" ] && ok "1장 done" || bad "1장" done "$S1"
[ "$S2" = "writing" ] && ok "2장만 열림" || bad "2장" writing "$S2"
[ "$S3" = "locked" ] && ok "3장은 여전히 locked" || bad "3장" locked "$S3"
NEXTQ=$(j next_question.id)
[ -n "$NEXTQ" ] && ok "다음 장의 첫 질문으로 이어짐" || bad "next_question" "있음" ""

step "15. 자서전"
req GET /book "" "$AT"
expect "GET /book 200" 200
[ "$(j author_name)" = "김영희" ] && ok "author_name=김영희" || bad "author_name" "김영희" "$(j author_name)"
[ "$(j chapter_count)" = "10" ] && ok "chapter_count=10" || bad "chapter_count" 10 "$(j chapter_count)"
PC=$(j page_count); QC=$(j question_count)
[ "$(j is_complete)" = "false" ] && ok "is_complete=false (아직 1장만 done)" || bad "is_complete" false "$(j is_complete)"
ok "완료 질문 ${QC}개 → ${PC}쪽"

req GET /book/pages "" "$AT"
expect "GET /book/pages 200" 200
PN=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).items.length")
[ "$PN" = "$PC" ] && ok "쪽 수 일치 ($PN)" || bad "쪽 수" "$PC" "$PN"
TP=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).items[0].total_pages")
[ "$TP" = "$PN" ] && ok "쪽마다 total_pages가 실린다" || bad "total_pages" "$PN" "$TP"
ONLY1=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).items.every(p=>p.chapter_order===1)")
[ "$ONLY1" = "true" ] && ok "done이 아닌 장은 한 글자도 안 실린다" || bad "done 장만" true "$ONLY1"
SKIPPED=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).items.flatMap(p=>p.paragraphs).join('|')")
case "$SKIPPED" in *"어머니와 형이"*) ok "꼬리답변이 본문에 포함" ;; *) bad "본문 내용" "꼬리답변 포함" "$SKIPPED" ;; esac

step "16. 홈 진행률 반영"
req GET /home "" "$AT"
[ "$(j chapter_done)" = "1" ] && ok "chapter_done=1" || bad "chapter_done" 1 "$(j chapter_done)"
RQ1=$(j remaining_questions)
[ "$RQ1" -lt "$RQ0" ] && ok "남은 질문 $RQ0 → $RQ1" || bad "remaining" "<$RQ0" "$RQ1"

step "17. 알림"
psql -d lifelegacy_app -qtAX -c "insert into notification (user_id,type,title) select id,'daily_question','오늘의 질문이 도착했어요' from app_user where phone='$PHONE'" > /dev/null
req GET /notifications "" "$AT"
expect "GET /notifications 200" 200
UNREAD=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).items.filter(n=>!n.is_read).length")
[ "$UNREAD" = "1" ] && ok "안 읽은 알림 1건" || bad "안 읽은 수" 1 "$UNREAD"
TL=$(printf '%s' "$BODY" | node -pe "(JSON.parse(require('fs').readFileSync(0)).items[0]||{}).time_label||''")
[ -n "$TL" ] && ok "상대 시각 라벨: $TL" || bad "time_label" "있음" ""
req POST /notifications/read-all "" "$AT"
expect "POST /notifications/read-all 200" 200
UNREAD=$(printf '%s' "$BODY" | node -pe "JSON.parse(require('fs').readFileSync(0)).items.filter(n=>!n.is_read).length")
[ "$UNREAD" = "0" ] && ok "갱신된 목록을 바로 돌려준다 (안 읽은 0건)" || bad "안 읽은 수" 0 "$UNREAD"

step "18. 설정 · 배송지"
req GET /settings "" "$AT"
expect "GET /settings 200" 200
req PATCH /settings '{"daily_question_alarm":false}' "$AT"
expect "PATCH /settings 200" 200
[ "$(j daily_question_alarm)" = "false" ] && ok "알림 끄기 반영" || bad "daily_question_alarm" false "$(j daily_question_alarm)"
req GET /settings "" "$AT"
[ "$(j daily_question_alarm)" = "false" ] && ok "다시 읽어도 유지" || bad "재조회" false "$(j daily_question_alarm)"

req GET /shipping-address "" "$AT"
expect "GET /shipping-address 200" 200
req PUT /shipping-address '{"recipient":"김영희","phone":"01011112222","postal_code":"06236","line1":"서울시 강남구","line2":"101동 202호"}' "$AT"
expect "PUT /shipping-address 200" 200
[ "$(j postal_code)" = "06236" ] && ok "배송지 저장" || bad "postal_code" "06236" "$(j postal_code)"
req GET /shipping-address "" "$AT"
[ "$(j line1)" = "서울시 강남구" ] && ok "다시 읽어도 유지" || bad "line1" "서울시 강남구" "$(j line1)"

step "19. 토큰 회전"
req POST /auth/refresh "{\"refresh_token\":\"$RT\"}"
expect "POST /auth/refresh 200" 200
AT2=$(j access_token); RT2=$(j refresh_token)
[ "$AT2" != "$AT" ] && ok "access 새로 발급" || bad "access" "다름" "같음"
[ "$RT2" != "$RT" ] && ok "refresh도 회전" || bad "refresh" "다름" "같음"
req POST /auth/refresh "{\"refresh_token\":\"$RT\"}"
expect "쓴 refresh 재사용 → 401" 401
req GET /users/me "" "$AT2"
expect "새 access로 조회 200" 200

req POST /auth/refresh "{\"refresh_token\":\"$RT2\"}"
RT3=$(j refresh_token)
req POST /auth/refresh "{\"refresh_token\":\"$RT3\"}"
RT4=$(j refresh_token)
[ "$RT3" != "$RT4" ] && ok "연속 갱신에도 토큰이 달라진다 (jti 회귀)" || bad "연속 갱신" "다름" "같음"

step "20. 로그아웃"
req POST /auth/logout "" "$AT2"
expect "POST /auth/logout 204" 204
req POST /auth/refresh "{\"refresh_token\":\"$RT4\"}"
expect "로그아웃 뒤 refresh → 401" 401

step "21. 재로그인 — 이번엔 needs_intro=false"
req POST /auth/phone/code "{\"phone\":\"$PHONE\"}" > /dev/null
sleep 31
req POST /auth/phone/code "{\"phone\":\"$PHONE\"}"
req POST /auth/phone/verify "{\"phone\":\"$PHONE\",\"code\":\"482915\"}"
expect "재로그인 200" 200
[ "$(j needs_intro)" = "false" ] && ok "목차 확정한 사용자는 needs_intro=false" || bad "needs_intro" false "$(j needs_intro)"
AT3=$(j access_token)
req GET /home "" "$AT3"
[ "$(j chapter_done)" = "1" ] && ok "진행 상태 유지" || bad "chapter_done" 1 "$(j chapter_done)"

step "22. 사용자 격리"
P2="0108${RANDOM}${RANDOM}"; P2="${P2:0:11}"
req POST /auth/phone/code "{\"phone\":\"$P2\"}" > /dev/null
req POST /auth/phone/verify "{\"phone\":\"$P2\",\"code\":\"482915\"}"
BT=$(j access_token)
req GET "/questions/$QID" "" "$BT"
expect "남의 질문 조회 → 404 (403 아님)" 404
req POST "/questions/$QID/answer" '{"text":"남의 질문에 답하기","input_mode":"keyboard"}' "$BT"
expect "남의 질문에 답하기 → 404" 404
req GET /book "" "$BT"
[ "$(j page_count)" = "0" ] && ok "새 사용자의 자서전은 비어 있다" || bad "page_count" 0 "$(j page_count)"

printf '\n\033[1m═══ 결과: %d 통과 · %d 실패 ═══\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" = "0" ]
