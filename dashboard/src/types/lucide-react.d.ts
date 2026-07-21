declare module "lucide-react" {
  import type { ComponentType, SVGProps } from "react";

  export type LucideIcon = ComponentType<
    SVGProps<SVGSVGElement> & { size?: string | number }
  >;
  export const ClipboardList: LucideIcon;
  export const LayoutDashboard: LucideIcon;
  export const MapPin: LucideIcon;
  export const Search: LucideIcon;
}
