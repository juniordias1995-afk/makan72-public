import { Check, X } from "lucide-react";

const comparisons = [
  { feature: "Memória entre sessões", tradicional: false, makan72: true },
  { feature: "Agnóstico de IA", tradicional: false, makan72: true },
  { feature: "Disciplina operacional", tradicional: false, makan72: true },
  { feature: "Prevenção de erros repetidos", tradicional: false, makan72: true },
  { feature: "Alinhamento com preferências do CEO", tradicional: false, makan72: true },
  { feature: "Framework genérico", tradicional: true, makan72: false },
  { feature: "Depende de um modelo específico", tradicional: true, makan72: false },
  { feature: "Curva de aprendizagem alta", tradicional: true, makan72: false },
];

export default function ComparisonTable() {
  return (
    <section className="py-20">
      <div className="mx-auto max-w-6xl px-6">
        <div className="text-center">
          <h2 className="font-display text-3xl font-bold md:text-5xl">
            Porquê{" "}
            <span className="bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
              Makan72
            </span>
          </h2>
          <p className="mt-4 text-text-secondary">
            Compare com soluções tradicionais
          </p>
        </div>

        <div className="mt-12 overflow-hidden rounded-2xl border border-border">
          <table className="w-full">
            <thead>
              <tr className="border-b border-border bg-bg-surface">
                <th className="px-6 py-4 text-left text-sm font-medium text-text-secondary">
                  Funcionalidade
                </th>
                <th className="px-6 py-4 text-center text-sm font-medium text-text-secondary">
                  Tradicional
                </th>
                <th className="px-6 py-4 text-center text-sm font-medium text-primary">
                  Makan72
                </th>
              </tr>
            </thead>
            <tbody>
              {comparisons.map((row) => (
                <tr
                  key={row.feature}
                  className="border-b border-border transition-colors hover:bg-bg-surface/50"
                >
                  <td className="px-6 py-4 text-text-primary">{row.feature}</td>
                  <td className="px-6 py-4 text-center">
                    {row.tradicional ? (
                      <X className="mx-auto h-5 w-5 text-red-500" />
                    ) : (
                      <Check className="mx-auto h-5 w-5 text-green-500" />
                    )}
                  </td>
                  <td className="px-6 py-4 text-center">
                    {row.makan72 ? (
                      <Check className="mx-auto h-5 w-5 text-primary glow-primary" />
                    ) : (
                      <X className="mx-auto h-5 w-5 text-red-500" />
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  );
}
