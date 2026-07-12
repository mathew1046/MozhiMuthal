import { Sidebar } from "@/components/sidebar";
import { Badge } from "@/components/ui/badge";
import { recentScreenings } from "@/lib/mock-data";

export default function ScreeningsPage() {
  return (
    <div className="flex min-h-screen w-full">
      <Sidebar />

      <main className="flex-1 p-6 lg:p-8 max-w-6xl space-y-6 bg-slate-50 dark:bg-slate-950">
        <div>
          <h1 className="text-xl font-bold tracking-tight">Screenings</h1>
          <p className="text-sm text-slate-500 mt-0.5">
            All recent screening records
          </p>
        </div>

        <div className="rounded-lg border bg-white dark:bg-slate-900 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-slate-50 dark:bg-slate-800/50">
                  <th className="text-left px-5 py-2.5 font-medium text-slate-500">ID</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">District</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Age</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Date</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Biomarkers</th>
                  <th className="text-left px-4 py-2.5 font-medium text-slate-500">Risk</th>
                </tr>
              </thead>
              <tbody>
                {recentScreenings.map((s) => (
                  <tr
                    key={s.id}
                    className="border-b last:border-b-0 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors"
                  >
                    <td className="px-5 py-2.5 font-medium">{s.id}</td>
                    <td className="px-4 py-2.5 text-slate-500">{s.district}</td>
                    <td className="px-4 py-2.5 text-slate-500">{s.age}m</td>
                    <td className="px-4 py-2.5 text-slate-500">{s.date}</td>
                    <td className="px-4 py-2.5">
                      <div className="flex gap-1">
                        {s.flagged.length > 0 ? (
                          s.flagged.map((f) => (
                            <Badge key={f} variant="outline" className="text-[10px] px-1.5 py-0">
                              {f}
                            </Badge>
                          ))
                        ) : (
                          <span className="text-xs text-slate-400">—</span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-2.5">
                      <Badge
                        variant={
                          s.result === "RED"
                            ? "destructive"
                            : s.result === "YELLOW"
                            ? "secondary"
                            : "outline"
                        }
                        className={
                          s.result === "GREEN"
                            ? "border-emerald-200 text-emerald-600 bg-emerald-50"
                            : ""
                        }
                      >
                        {s.result}
                      </Badge>
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
