import Link from "next/link";
import { Sidebar } from "@/components/sidebar";
import { Badge } from "@/components/ui/badge";
import { flaggedBiomarkers, getScreenings } from "@/lib/screening-data";

type Props = {
  searchParams?: Promise<Record<string, string | undefined>> | Record<string, string | undefined>;
};

export default async function ScreeningsPage({ searchParams }: Props) {
  const params = await Promise.resolve(searchParams ?? {});
  const childId = params.childId?.trim() || undefined;
  const { data: screenings, error } = await getScreenings(childId);

  return (
    <div className="flex min-h-screen w-full">
      <Sidebar />

      <main className="flex-1 p-6 lg:p-8 max-w-6xl space-y-6 bg-slate-50 dark:bg-slate-950">
        <div>
          <h1 className="text-xl font-bold tracking-tight">Screenings</h1>
          <p className="text-sm text-slate-500 mt-0.5">
            {childId ? `Screening records for child ${childId}` : "All recent screening records"}
          </p>
        </div>

        {error ? (
          <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
            {error}
          </div>
        ) : null}

        <div className="rounded-lg border bg-white dark:bg-slate-900 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-slate-50 dark:bg-slate-800/50">
                  <th className="text-left px-5 py-2.5 font-medium text-slate-500">Session</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Child ID</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">District</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Age</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Date</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Biomarkers</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Risk</th>
                </tr>
              </thead>
              <tbody>
                {screenings.map((s) => (
                  <tr
                    key={s.session_id}
                    className="border-b last:border-b-0 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors"
                  >
                    <td className="px-5 py-2.5 font-medium">
                      <Link href={`/children?childId=${s.child_id}`} className="underline underline-offset-2">
                        {s.session_id.slice(0, 8)}
                      </Link>
                    </td>
                    <td className="px-4 py-2.5 text-slate-500 font-mono text-xs">{s.child_id}</td>
                    <td className="px-4 py-2.5 text-slate-500">{s.district_code ?? "-"}</td>
                    <td className="px-4 py-2.5 text-slate-500">{s.age_months ?? "-"}m</td>
                    <td className="px-4 py-2.5 text-slate-500">{new Date(s.screened_at).toLocaleDateString()}</td>
                    <td className="px-4 py-2.5">
                      <div className="flex gap-1">
                        {flaggedBiomarkers(s).length > 0 ? (
                          flaggedBiomarkers(s).map((f) => (
                            <Badge key={f} variant="outline" className="text-[10px] px-1.5 py-0">
                              {f}
                            </Badge>
                          ))
                        ) : (
                          <span className="text-xs text-slate-400">-</span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-2.5">
                      <RiskBadge risk={s.risk_level ?? "green"} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}

function RiskBadge({ risk }: { risk: string }) {
  const upper = risk.toUpperCase();
  return (
    <Badge
      variant={upper === "RED" ? "destructive" : upper === "YELLOW" ? "secondary" : "outline"}
      className={upper === "GREEN" ? "border-emerald-200 text-emerald-600 bg-emerald-50" : ""}
    >
      {upper}
    </Badge>
  );
}
