import { Badge } from "@/components/ui/badge";

interface DistrictRow {
  code: string;
  name: string;
  total: number;
  red: number;
  yellow: number;
  green: number;
}

export function DistrictTable({ data }: { data: DistrictRow[] }) {
  return (
    <div className="rounded-lg border bg-white dark:bg-slate-900 overflow-hidden">
      <div className="px-5 py-3 border-b">
        <h3 className="text-sm font-semibold">District Breakdown</h3>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b bg-slate-50 dark:bg-slate-800/50">
              <th className="text-left px-5 py-2.5 font-medium text-slate-500">District</th>
              <th className="text-right px-4 py-2.5 font-medium text-slate-500">Total</th>
              <th className="text-right px-4 py-2.5 font-medium text-red-500">Red</th>
              <th className="text-right px-4 py-2.5 font-medium text-amber-500">Yellow</th>
              <th className="text-right px-4 py-2.5 font-medium text-emerald-500">Green</th>
              <th className="text-right px-5 py-2.5 font-medium text-slate-500">Red %</th>
            </tr>
          </thead>
          <tbody>
            {data.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-5 py-8 text-center text-sm text-slate-500">
                  No synced screening data is available.
                </td>
              </tr>
            ) : data.map((d) => (
              <tr key={d.code} className="border-b last:border-b-0 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                <td className="px-5 py-2.5 font-medium">{d.name}</td>
                <td className="text-right px-4 py-2.5 text-slate-500">{d.total}</td>
                <td className="text-right px-4 py-2.5">
                  <Badge variant="destructive" className="text-[11px] px-1.5 py-0">
                    {d.red}
                  </Badge>
                </td>
                <td className="text-right px-4 py-2.5">
                  <span className="text-amber-600 font-medium">{d.yellow}</span>
                </td>
                <td className="text-right px-4 py-2.5">
                  <span className="text-emerald-600">{d.green}</span>
                </td>
                <td className="text-right px-5 py-2.5 text-slate-400 text-xs">
                  {d.total > 0 ? ((d.red / d.total) * 100).toFixed(1) : "0.0"}%
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
