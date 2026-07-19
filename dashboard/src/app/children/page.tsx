import { Sidebar } from "@/components/sidebar";
import { Badge } from "@/components/ui/badge";
import { getScreenings, type ScreeningAnalysis } from "@/lib/screening-data";

type Props = {
  searchParams?: Promise<Record<string, string | undefined>> | Record<string, string | undefined>;
};

export default async function ChildrenPage({ searchParams }: Props) {
  const params = await Promise.resolve(searchParams ?? {});
  const childId = params.childId?.trim() || undefined;
  const { data: sessions, error } = await getScreenings(childId);
  const child = sessions[0];

  return (
    <div className="flex min-h-screen w-full">
      <Sidebar />
      <main className="flex-1 p-6 lg:p-8 max-w-6xl space-y-6 bg-slate-50 dark:bg-slate-950">
        <div>
          <h1 className="text-xl font-bold tracking-tight">Child Analysis</h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Select a child by UUID and inspect why each screening was classified.
          </p>
        </div>

        <form action="/children" className="rounded-lg border bg-white dark:bg-slate-900 p-4 flex gap-3">
          <input
            name="childId"
            defaultValue={childId}
            placeholder="Paste child UUID"
            className="min-w-0 flex-1 rounded-md border bg-transparent px-3 py-2 text-sm"
          />
          <button className="rounded-md bg-slate-900 px-4 py-2 text-sm font-medium text-white dark:bg-white dark:text-slate-900">
            Search
          </button>
        </form>

        {error ? (
          <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
            {error}
          </div>
        ) : null}

        {!childId ? (
          <div className="rounded-lg border bg-white dark:bg-slate-900 p-5 text-sm text-slate-500">
            Enter a child UUID from the mobile app or screenings table.
          </div>
        ) : sessions.length === 0 ? (
          <div className="rounded-lg border bg-white dark:bg-slate-900 p-5 text-sm text-slate-500">
            No synced sessions found for this child ID.
          </div>
        ) : (
          <>
            <div className="rounded-lg border bg-white dark:bg-slate-900 p-5">
              <h2 className="font-semibold">{child?.pseudonym ?? "Child"}</h2>
              <p className="mt-1 font-mono text-xs text-slate-500">{child?.child_id}</p>
              <p className="mt-2 text-sm text-slate-500">
                District {child?.district_code ?? "-"} · Anganwadi {child?.anganwadi_id ?? "-"} · DOB {child?.birth_date ?? "-"}
              </p>
            </div>
            {sessions.map((session) => (
              <SessionAnalysis key={session.session_id} session={session} />
            ))}
          </>
        )}
      </main>
    </div>
  );
}

function SessionAnalysis({ session }: { session: ScreeningAnalysis }) {
  const analysis = session.questionnaire_analysis ?? {};
  const domains = Object.values((analysis.domains ?? {}) as Record<string, Record<string, unknown>>);
  const questions = ((analysis.questions ?? []) as Record<string, unknown>[]).filter(
    (q) => q.severity !== "normal",
  );

  return (
    <section className="rounded-lg border bg-white dark:bg-slate-900 p-5 space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h3 className="font-semibold">Session {session.session_id.slice(0, 8)}</h3>
          <p className="text-xs text-slate-500">{new Date(session.screened_at).toLocaleString()}</p>
        </div>
        <Badge variant={session.risk_level === "red" ? "destructive" : "secondary"}>
          {(session.risk_level ?? "green").toUpperCase()}
        </Badge>
      </div>

      <div className="grid gap-3 sm:grid-cols-3">
        <Metric label="VTTL" value={`${Math.round(session.vttl_ms ?? 0)} ms`} />
        <Metric label="CVR" value={(session.cvr_ratio ?? 0).toFixed(3)} />
        <Metric label="PFV" value={(session.pfv_std ?? 0).toFixed(2)} />
      </div>

      <div>
        <h4 className="text-sm font-semibold">MyChild domain analysis</h4>
        <div className="mt-3 grid gap-3 md:grid-cols-2">
          {domains.map((domain) => (
            <div key={String(domain.domain_tag)} className="rounded-md border p-3">
              <div className="flex items-center justify-between gap-2">
                <span className="font-medium text-sm">{String(domain.domain)}</span>
                <Badge variant="outline">{String(domain.status).replaceAll("_", " ")}</Badge>
              </div>
              <p className="mt-2 text-xs text-slate-500">{String(domain.explanation)}</p>
            </div>
          ))}
        </div>
      </div>

      <div>
        <h4 className="text-sm font-semibold">Why the model flagged this child</h4>
        <div className="mt-3 space-y-3">
          {questions.length === 0 ? (
            <p className="text-sm text-slate-500">No questionnaire item was flagged beyond normal.</p>
          ) : (
            questions.map((question) => <QuestionExplanation key={String(question.question_id ?? question.question)} question={question} />)
          )}
        </div>
      </div>
    </section>
  );
}

function QuestionExplanation({ question }: { question: Record<string, unknown> }) {
  const q = question.question as Record<string, unknown> | undefined;
  const detail = question.detail as Record<string, unknown> | undefined;
  return (
    <div className="rounded-md border p-3 text-sm">
      <div className="flex items-center justify-between gap-2">
        <span className="font-medium">{String(q?.text_ml ?? q?.text ?? "Question")}</span>
        <Badge variant="outline">{String(question.severity)}</Badge>
      </div>
      <p className="mt-1 text-xs text-slate-500">{String(question.explanation ?? "")}</p>
      <p className="mt-2 text-xs"><span className="font-medium">Applied rule:</span> {String(detail?.applied_rule ?? "-")}</p>
      <p className="mt-1 text-xs"><span className="font-medium">Action:</span> {String(detail?.recommended_action ?? "-")}</p>
    </div>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-md border p-3">
      <div className="text-xs uppercase tracking-wide text-slate-500">{label}</div>
      <div className="mt-1 text-lg font-semibold">{value}</div>
    </div>
  );
}
