import { Sidebar } from "@/components/sidebar";
import { DistrictTable } from "@/components/district-table";
import { districts } from "@/lib/mock-data";

export default function DistrictsPage() {
  return (
    <div className="flex min-h-screen w-full">
      <Sidebar />

      <main className="flex-1 p-6 lg:p-8 max-w-6xl space-y-6 bg-slate-50 dark:bg-slate-950">
        <div>
          <h1 className="text-xl font-bold tracking-tight">Districts</h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Screening data across all 14 Kerala districts
          </p>
        </div>

        <DistrictTable data={districts} />
      </main>
    </div>
  );
}
