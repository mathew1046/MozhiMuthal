import { Sidebar } from "@/components/sidebar";
import { DistrictTable } from "@/components/district-table";
import { districtSummaries, getScreenings } from "@/lib/screening-data";

export default async function DistrictsPage() {
  const { data: screenings, error } = await getScreenings();
  const districts = districtSummaries(screenings);

  return (
    <div className="flex min-h-screen w-full">
      <Sidebar />

      <main className="flex-1 p-6 lg:p-8 max-w-6xl space-y-6 bg-slate-50 dark:bg-slate-950">
        <div>
          <h1 className="text-xl font-bold tracking-tight">Districts</h1>
          <p className="text-sm text-slate-500 mt-0.5">
            District totals from the 100 most recent synced screening sessions
          </p>
        </div>

        {error ? (
          <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
            {error}
          </div>
        ) : null}

        <DistrictTable data={districts} />
      </main>
    </div>
  );
}
