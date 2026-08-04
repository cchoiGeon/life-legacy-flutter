/**
 * CLOVA TTS Premium 화자 목록
 * 출처: https://api.ncloud-docs.com/docs/ai-naver-clovavoice-ttspremium
 * (음성 합성 목소리 목록 — 한국어)
 */

export type ClovaVoiceGender = "female" | "male";
export type ClovaVoiceAge = "adult" | "child" | "character";

export type ClovaTtsVoice = {
  voiceId: string;
  /** 표시명 (한국어) */
  name: string;
  gender: ClovaVoiceGender;
  age: ClovaVoiceAge;
  /** NeuVis Pro 엔진 */
  pro?: boolean;
  /** emotion 파라미터 지원 */
  supportsEmotion?: boolean;
  /** emotion-strength 파라미터 지원 (nara 제외) */
  supportsEmotionStrength?: boolean;
};

export const CLOVA_TTS_DEFAULT_SPEAKER = "vara";

/** emotion 지원 화자 (공식 문서) */
const EMOTION_SPEAKERS = new Set([
  "nara",
  "vara",
  "vmikyung",
  "vdain",
  "vyuna",
  "vgoeun",
  "vdaeseong",
]);

/** emotion-strength 지원 화자 (공식 문서 — nara 미포함) */
const EMOTION_STRENGTH_SPEAKERS = new Set([
  "vara",
  "vmikyung",
  "vdain",
  "vyuna",
  "vgoeun",
  "vdaeseong",
]);

function v(
  voiceId: string,
  name: string,
  gender: ClovaVoiceGender,
  age: ClovaVoiceAge,
  opts?: { pro?: boolean }
): ClovaTtsVoice {
  return {
    voiceId,
    name,
    gender,
    age,
    pro: opts?.pro,
    supportsEmotion: EMOTION_SPEAKERS.has(voiceId),
    supportsEmotionStrength: EMOTION_STRENGTH_SPEAKERS.has(voiceId),
  };
}

/**
 * 한국어 화자 전체 (자서전/오디오북용).
 * 외국어·이중언어 화자는 제외.
 */
export const CLOVA_TTS_VOICES: ClovaTtsVoice[] = [
  // —— Pro (NeuVis) ——
  v("vara", "아라(Pro)", "female", "adult", { pro: true }),
  v("vgoeun", "고은(Pro)", "female", "adult", { pro: true }),
  v("vmikyung", "미경(Pro)", "female", "adult", { pro: true }),
  v("vyuna", "유나(Pro)", "female", "adult", { pro: true }),
  v("vhyeri", "혜리(Pro)", "female", "adult", { pro: true }),
  v("vdain", "다인(Pro)", "female", "adult", { pro: true }),
  v("vdaeseong", "대성(Pro)", "male", "adult", { pro: true }),
  v("vdonghyun", "동현(Pro)", "male", "adult", { pro: true }),
  v("vian", "이안(Pro)", "male", "adult", { pro: true }),

  // —— 성인 여성 ——
  v("nara", "아라", "female", "adult"),
  v("nara_call", "아라(상담원)", "female", "adult"),
  v("dara_ang", "아라(화남)", "female", "adult"),
  v("ngoeun", "고은", "female", "adult"),
  v("nes_c_mikyung", "미경", "female", "adult"),
  v("nes_c_hyeri", "혜리", "female", "adult"),
  v("nes_c_sohyun", "소현", "female", "adult"),
  v("nyuna", "유나", "female", "adult"),
  v("nyoungmi", "영미", "female", "adult"),
  v("nbora", "보라", "female", "adult"),
  v("napple", "늘봄", "female", "adult"),
  v("mijin", "미진", "female", "adult"),
  v("nmijin", "미진(n)", "female", "adult"),
  v("nminjeong", "민정", "female", "adult"),
  v("nminseo", "민서", "female", "adult"),
  v("nminyoung", "민영", "female", "adult"),
  v("neunseo", "은서", "female", "adult"),
  v("neunyoung", "은영", "female", "adult"),
  v("nheera", "희라", "female", "adult"),
  v("nihyun", "이현", "female", "adult"),
  v("njiwon", "지원", "female", "adult"),
  v("njiyun", "지윤", "female", "adult"),
  v("njangj", "드림", "female", "adult"),
  v("nkyunglee", "경리", "female", "adult"),
  v("noyj", "봄달", "female", "adult"),
  v("nshasha", "샤샤", "female", "adult"),
  v("nsujin", "수진", "female", "adult"),
  v("nsunhee", "선희", "female", "adult"),
  v("nsunkyung", "선경", "female", "adult"),
  v("ntiffany", "기서", "female", "adult"),
  v("nyeji", "예지", "female", "adult"),
  v("nyejin", "예진", "female", "adult"),
  v("nyounghwa", "정영화", "female", "adult"),
  v("nyujin", "유진", "female", "adult"),

  // —— 성인 남성 ——
  v("njinho", "진호", "male", "adult"),
  v("jinho", "진호(레거시)", "male", "adult"),
  v("ndaeseong", "대성", "male", "adult"),
  v("ndonghyun", "동현", "male", "adult"),
  v("nian", "이안", "male", "adult"),
  v("nes_c_kihyo", "기효", "male", "adult"),
  v("nminsang", "민상", "male", "adult"),
  v("nsinu", "신우", "male", "adult"),
  v("nkyungtae", "경태", "male", "adult"),
  v("neunwoo", "은우", "male", "adult"),
  v("ngyeongjun", "경준", "male", "adult"),
  v("njaewook", "재욱", "male", "adult"),
  v("njihun", "지훈", "male", "adult"),
  v("njihwan", "지환", "male", "adult"),
  v("njonghyeok", "종혁", "male", "adult"),
  v("njonghyun", "종현", "male", "adult"),
  v("njooahn", "주안", "male", "adult"),
  v("njoonyoung", "준영", "male", "adult"),
  v("nkitae", "기태", "male", "adult"),
  v("nkyuwon", "규원", "male", "adult"),
  v("nraewon", "래원", "male", "adult"),
  v("nsangdo", "상도", "male", "adult"),
  v("nseonghoon", "성훈", "male", "adult"),
  v("nseungpyo", "승표", "male", "adult"),
  v("nsiyoon", "시윤", "male", "adult"),
  v("ntaejin", "태진", "male", "adult"),
  v("nwontak", "원탁", "male", "adult"),
  v("nwoosik", "우식", "male", "adult"),
  v("nyoungil", "영일", "male", "adult"),

  // —— 아동 ——
  v("ndain", "다인", "female", "child"),
  v("ngaram", "가람", "female", "child"),
  v("nhajun", "하준", "male", "child"),

  // —— 캐릭터/특수 ——
  v("nmeow", "야옹이", "female", "character"),
  v("nwoof", "멍멍이", "male", "character"),
  v("nsabina", "마녀 사비나", "female", "character"),
  v("nmammon", "악마 마몬", "male", "character"),
  v("nmovie", "최무비", "male", "character"),
  v("nreview", "박리뷰", "male", "character"),
];

export type ClovaVoiceGroupId =
  | "pro-female"
  | "pro-male"
  | "adult-female"
  | "adult-male"
  | "child-female"
  | "child-male"
  | "character";

export type ClovaVoiceGroup = {
  id: ClovaVoiceGroupId;
  label: string;
  voices: ClovaTtsVoice[];
};

/** Admin UI용 성별·연령 그룹 */
export function getClovaVoiceGroups(): ClovaVoiceGroup[] {
  const defs: { id: ClovaVoiceGroupId; label: string; filter: (v: ClovaTtsVoice) => boolean }[] = [
    {
      id: "pro-female",
      label: "성인 여성 · Pro",
      filter: (x) => x.pro === true && x.gender === "female",
    },
    {
      id: "pro-male",
      label: "성인 남성 · Pro",
      filter: (x) => x.pro === true && x.gender === "male",
    },
    {
      id: "adult-female",
      label: "성인 여성",
      filter: (x) => !x.pro && x.age === "adult" && x.gender === "female",
    },
    {
      id: "adult-male",
      label: "성인 남성",
      filter: (x) => !x.pro && x.age === "adult" && x.gender === "male",
    },
    {
      id: "child-female",
      label: "아동 여성",
      filter: (x) => x.age === "child" && x.gender === "female",
    },
    {
      id: "child-male",
      label: "아동 남성",
      filter: (x) => x.age === "child" && x.gender === "male",
    },
    {
      id: "character",
      label: "캐릭터 / 특수",
      filter: (x) => x.age === "character",
    },
  ];

  return defs
    .map((d) => ({
      id: d.id,
      label: d.label,
      voices: CLOVA_TTS_VOICES.filter(d.filter),
    }))
    .filter((g) => g.voices.length > 0);
}

export function getClovaDefaultSpeaker(): string {
  return process.env.CLOVA_TTS_DEFAULT_SPEAKER?.trim() || CLOVA_TTS_DEFAULT_SPEAKER;
}

export function isKnownClovaSpeaker(speaker: string): boolean {
  return CLOVA_TTS_VOICES.some((v) => v.voiceId === speaker);
}

export function getClovaVoice(voiceId: string): ClovaTtsVoice | undefined {
  return CLOVA_TTS_VOICES.find((v) => v.voiceId === voiceId);
}

/** 앱 음성 선택용 — Pro + 성인 (아동·캐릭터 제외) */
export function listClovaVoicesForApp(): ClovaTtsVoice[] {
  return CLOVA_TTS_VOICES.filter(
    (v) => v.age === 'adult' || v.pro === true,
  );
}
