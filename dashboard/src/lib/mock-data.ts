// Mock data for the dashboard — will be replaced with Supabase queries later
export const districts = [
  { code: "TVM", name: "Thiruvananthapuram", total: 142, red: 5, yellow: 12, green: 125 },
  { code: "KLM", name: "Kollam", total: 98, red: 3, yellow: 8, green: 87 },
  { code: "PTA", name: "Pathanamthitta", total: 64, red: 1, yellow: 5, green: 58 },
  { code: "ALP", name: "Alappuzha", total: 88, red: 4, yellow: 7, green: 77 },
  { code: "KTM", name: "Kottayam", total: 76, red: 2, yellow: 6, green: 68 },
  { code: "IDK", name: "Idukki", total: 52, red: 6, yellow: 4, green: 42 },
  { code: "EKM", name: "Ernakulam", total: 134, red: 4, yellow: 11, green: 119 },
  { code: "TSR", name: "Thrissur", total: 112, red: 3, yellow: 9, green: 100 },
  { code: "PKD", name: "Palakkad", total: 96, red: 5, yellow: 8, green: 83 },
  { code: "MLP", name: "Malappuram", total: 148, red: 7, yellow: 14, green: 127 },
  { code: "KKD", name: "Kozhikode", total: 118, red: 4, yellow: 10, green: 104 },
  { code: "WYD", name: "Wayanad", total: 38, red: 3, yellow: 3, green: 32 },
  { code: "KNR", name: "Kannur", total: 92, red: 2, yellow: 7, green: 83 },
  { code: "KSD", name: "Kasaragod", total: 56, red: 3, yellow: 5, green: 48 },
];

export const recentScreenings = [
  { id: "S-1042", district: "Idukki", age: 28, result: "RED" as const, date: "2026-07-11", flagged: ["VTTL", "CVR"] },
  { id: "S-1043", district: "Wayanad", age: 36, result: "GREEN" as const, date: "2026-07-11", flagged: [] },
  { id: "S-1044", district: "Kozhikode", age: 18, result: "YELLOW" as const, date: "2026-07-10", flagged: ["VTTL"] },
  { id: "S-1045", district: "Idukki", age: 42, result: "RED" as const, date: "2026-07-10", flagged: ["PFV", "CVR"] },
  { id: "S-1046", district: "Malappuram", age: 24, result: "YELLOW" as const, date: "2026-07-10", flagged: ["CVR"] },
  { id: "S-1047", district: "Thrissur", age: 30, result: "RED" as const, date: "2026-07-09", flagged: ["VTTL", "PFV"] },
  { id: "S-1048", district: "Ernakulam", age: 15, result: "GREEN" as const, date: "2026-07-09", flagged: [] },
  { id: "S-1049", district: "Palakkad", age: 48, result: "RED" as const, date: "2026-07-09", flagged: ["VTTL", "CVR", "PFV"] },
];

export function getTotals() {
  return districts.reduce(
    (acc, d) => ({
      total: acc.total + d.total,
      red: acc.red + d.red,
      yellow: acc.yellow + d.yellow,
      green: acc.green + d.green,
    }),
    { total: 0, red: 0, yellow: 0, green: 0 }
  );
}
