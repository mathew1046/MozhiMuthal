interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  color?: "default" | "red" | "yellow" | "green";
}

const colorMap = {
  default: "text-slate-900 dark:text-white",
  red: "text-red-600",
  yellow: "text-amber-600",
  green: "text-emerald-600",
};

export function StatCard({ title, value, subtitle, color = "default" }: StatCardProps) {
  return (
    <div className="rounded-lg border bg-white dark:bg-slate-900 p-5">
      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide">
        {title}
      </p>
      <p className={`text-2xl font-bold mt-1 ${colorMap[color]}`}>{value}</p>
      {subtitle && (
        <p className="text-xs text-slate-400 mt-0.5">{subtitle}</p>
      )}
    </div>
  );
}
