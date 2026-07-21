import { createSupabaseAdmin } from "./supabase-admin";

export type ScreeningAnalysis = {
  child_id: string;
  pseudonym: string | null;
  birth_date: string | null;
  gestational_weeks: number | null;
  anganwadi_id: string | null;
  district_code: string | null;
  session_id: string;
  screened_at: string;
  risk_level: string | null;
  analysis_status: string | null;
  quality_reasons: string[] | null;
  vttl_ms: number | null;
  cvr_ratio: number | null;
  pfv_std: number | null;
  voiced_seconds: number | null;
  child_voiced_seconds: number | null;
  transition_count: number | null;
  audio_source: string | null;
  age_months: number | null;
  questionnaire_state: string | null;
  answers: Record<string, string> | null;
  questionnaire_analysis: Record<string, unknown> | null;
  decision_trace: unknown[] | null;
  waveform: number[] | null;
};

export async function getScreenings(childId?: string) {
  const supabase = createSupabaseAdmin();
  if (!supabase) {
    return { data: [] as ScreeningAnalysis[], error: "Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY for live dashboard data." };
  }

  let query = supabase
    .from("child_screening_analysis")
    .select("*")
    .order("screened_at", { ascending: false })
    .limit(100);

  if (childId) query = query.eq("child_id", childId);

  const { data, error } = await query;
  return { data: (data ?? []) as ScreeningAnalysis[], error: error?.message };
}

export function riskCounts(rows: ScreeningAnalysis[]) {
  return rows.reduce(
    (acc, row) => {
      const risk = (row.risk_level ?? "green").toLowerCase();
      if (risk === "red") acc.red++;
      else if (risk === "yellow") acc.yellow++;
      else acc.green++;
      acc.total++;
      return acc;
    },
    { total: 0, red: 0, yellow: 0, green: 0 },
  );
}

export function flaggedBiomarkers(row: ScreeningAnalysis) {
  const flags: string[] = [];
  if ((row.vttl_ms ?? 0) > 1000) flags.push("VTTL");
  if ((row.cvr_ratio ?? 1) < (row.age_months && row.age_months >= 24 ? 0.12 : 0.08)) flags.push("CVR");
  if ((row.age_months ?? 0) >= 36 && (row.pfv_std ?? 99) < 15) flags.push("PFV");
  return flags;
}
