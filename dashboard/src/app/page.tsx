import { Sidebar } from "@/components/sidebar";
import { StatCard } from "@/components/stat-card";
import { DistrictTable } from "@/components/district-table";
import { Badge } from "@/components/ui/badge";
import { districtSummaries, flaggedBiomarkers, getScreenings, riskCounts } from "@/lib/screening-data";

export default async function Dashboard() {
  const { data: screenings, error } = await getScreenings();
  const totals = riskCounts(screenings);
  const districts = districtSummaries(screenings);
  const hasScreenings = totals.total > 0;
  const percentage = (value: number) => hasScreenings ? ((value / totals.total) * 100).toFixed(1) : "0.0";

  return (
    <div className="flex min-h-screen w-full">
      <Sidebar />

      <main className="flex-1 p-6 lg:p-8 max-w-6xl space-y-6 bg-slate-50 dark:bg-slate-950">
        <div>
          <h1 className="text-xl font-bold tracking-tight">District Overview</h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Analytics from the 100 most recent synced screening sessions
          </p>
        </div>

        {error ? (
          <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
            {error}
          </div>
        ) : null}

        {/* Stat cards */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            title="Total Screenings"
            value={totals.total.toLocaleString()}
            subtitle={hasScreenings ? `Across ${districts.length} recorded districts` : "No synced sessions yet"}
          />
          <StatCard
            title="Red — Immediate DEIC"
            value={totals.red}
            subtitle={`${percentage(totals.red)}% of total`}
            color="red"
          />
          <StatCard
            title="Yellow — Watch"
            value={totals.yellow}
            subtitle="Re-screen in 3 months"
            color="yellow"
          />
          <StatCard
            title="Green — Normal"
            value={totals.green}
            subtitle="Age-appropriate development"
            color="green"
          />
        </div>

        {/* Risk distribution bar */}
        <div className="rounded-lg border bg-white dark:bg-slate-900 p-5">
          <h3 className="text-sm font-semibold mb-3">Risk Distribution</h3>
          <div className="flex h-4 rounded-full overflow-hidden">
            <div
              className="bg-red-500 transition-all"
              style={{ width: `${percentage(totals.red)}%` }}
            />
            <div
              className="bg-amber-400 transition-all"
              style={{ width: `${percentage(totals.yellow)}%` }}
            />
            <div
              className="bg-emerald-500 transition-all"
              style={{ width: `${percentage(totals.green)}%` }}
            />
          </div>
          <div className="flex gap-6 mt-2 text-xs text-slate-500">
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-red-500" />
              Red {percentage(totals.red)}%
            </span>
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-amber-400" />
              Yellow {percentage(totals.yellow)}%
            </span>
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-emerald-500" />
              Green {percentage(totals.green)}%
            </span>
          </div>
        </div>

        {/* District table */}
        <DistrictTable data={districts} />

        {/* Recent flagged screenings */}
        <div className="rounded-lg border bg-white dark:bg-slate-900 overflow-hidden">
          <div className="px-5 py-3 border-b">
            <h3 className="text-sm font-semibold">Recent Flagged Screenings</h3>
            <p className="text-xs text-slate-400 mt-0.5">
              RED and YELLOW cases requiring follow-up
            </p>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-slate-50 dark:bg-slate-800/50">
                  <th className="text-left px-5 py-2.5 font-medium text-slate-500">ID</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">District</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Age</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Biomarkers</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Risk</th>
                </tr>
              </thead>
              <tbody>
                {screenings
                  .filter((s) => (s.risk_level ?? "green").toUpperCase() !== "GREEN")
                  .map((s) => (
                    <tr
                      key={s.session_id}
                      className="border-b last:border-b-0 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors"
                    >
                      <td className="px-5 py-2.5 font-medium">{s.session_id.slice(0, 8)}</td>
                      <td className="px-4 py-2.5 text-slate-500">{s.district_code ?? "-"}</td>
                      <td className="px-4 py-2.5 text-slate-500">{s.age_months ?? "-"}m</td>
                      <td className="px-4 py-2.5">
                        <div className="flex gap-1">
                          {flaggedBiomarkers(s).map((f) => (
                            <Badge key={f} variant="outline" className="text-[10px] px-1.5 py-0">
                              {f}
                            </Badge>
                          ))}
                          {flaggedBiomarkers(s).length === 0 ? <span className="text-xs text-slate-400">-</span> : null}
                        </div>
                      </td>
                      <td className="px-4 py-2.5">
                        <Badge variant={(s.risk_level ?? "green").toUpperCase() === "RED" ? "destructive" : "secondary"}>
                          {(s.risk_level ?? "green").toUpperCase()}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                {screenings.filter((s) => (s.risk_level ?? "green").toUpperCase() !== "GREEN").length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-5 py-8 text-center text-sm text-slate-500">
                      No flagged synced screenings are available.
                    </td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}
