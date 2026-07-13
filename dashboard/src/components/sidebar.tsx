"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LayoutDashboard, MapPin, ClipboardList } from "lucide-react";

const nav = [
  { href: "/", label: "Overview", icon: LayoutDashboard },
  { href: "/districts", label: "Districts", icon: MapPin },
  { href: "/screenings", label: "Screenings", icon: ClipboardList },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-56 shrink-0 border-r bg-white dark:bg-slate-900 flex flex-col">
      {/* Brand */}
      <div className="px-5 py-4 border-b flex items-center gap-2">
        <div className="h-7 w-7 rounded-full bg-emerald-700 flex items-center justify-center">
          <span className="text-white text-xs font-bold">M</span>
        </div>
        <span className="font-semibold text-sm tracking-tight">MozhiMuthal</span>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-3 space-y-0.5">
        {nav.map((item) => {
          const active = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-2.5 px-3 py-2 rounded-md text-sm transition-colors ${
                active
                  ? "bg-slate-100 dark:bg-slate-800 font-medium text-slate-900 dark:text-white"
                  : "text-slate-500 hover:text-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800 dark:hover:text-white"
              }`}
            >
              <item.icon size={16} />
              {item.label}
            </Link>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="px-5 py-3 border-t text-[11px] text-slate-400">
        Kerala DEIC Network
      </div>
    </aside>
  );
}
