// lib/i18n.ts
// Módulo centralizado de traduções para Makan72.com
// Exporta funções e constantes para uso em toda a aplicação

import { Brain, Shield, Zap, RefreshCw, Lock, TrendingUp } from "lucide-react";

// ============================================================================
// TIPOS
// ============================================================================

export type Language = "PT" | "EN";

export interface Feature {
  icon: any;
  title: string;
  desc: string;
}

export interface HomeContent {
  featuresTitle: string;
  featuresSubtitle: string;
  features: Feature[];
  ctaTitle: string;
  ctaSubtitle: string;
  ctaButton: string;
}

export interface ContactContent {
  title: string;
  subtitle: string;
  form: {
    name: string;
    email: string;
    message: string;
    submit: string;
  };
}

export interface AboutContent {
  badge: string;
  title: string;
  p1: string;
  p2: string;
  p3: string;
  architecture: string;
  architectureDesc: string;
  benefits: string;
  benefitCards: Array<{
    title: string;
    desc: string;
  }>;
  nodes: Array<{
    label: string;
    sublabel: string;
    action: string;
  }>;
}

// ============================================================================
// CONTEÚDOS POR LINGUAGEM
// ============================================================================

export const homeContent: Record<Language, HomeContent> = {
  PT: {
    featuresTitle: "Seja o CEO dos seus agentes IA",
    featuresSubtitle: "No Makan72, você comanda. Os agentes obedecem. Memória permanente. Disciplina absoluta.",
    features: [
      {
        icon: Brain,
        title: "Zero Repetição",
        desc: "O que um agente aprende, todos herdam. Erros acontecem uma vez — nunca duas."
      },
      {
        icon: RefreshCw,
        title: "Troca Instantânea",
        desc: "Claude hoje. Gemini amanhã. Troque de IA como quem troca de roupa — sem perder uma única memória."
      },
      {
        icon: Shield,
        title: "Disciplina Militar",
        desc: "Regras rígidas aplicadas a todos. Zero improvisação. Zero desculpas. Resultados garantidos."
      },
      {
        icon: Zap,
        title: "Escalabilidade Total",
        desc: "Comece sozinho. Termine com um exército de agentes. O Makan72 cresce com você."
      },
      {
        icon: Lock,
        title: "Privacidade Absoluta",
        desc: "Seus dados são seus. Memória local, criptografada e sob seu controlo total."
      },
      {
        icon: TrendingUp,
        title: "Evolução Contínua",
        desc: "Cada sessão torna o sistema mais inteligente. Aprendizado acumulativo automático."
      },
    ],
    ctaTitle: "Pronto para Comandar?",
    ctaSubtitle: "Junte-se aos CEOs que já não perdem tempo a repetir instruções.",
    ctaButton: "Começar Agora",
  },
  EN: {
    featuresTitle: "Be the CEO of Your AI Agents",
    featuresSubtitle: "With Makan72, you command. Agents obey. Permanent memory. Absolute discipline.",
    features: [
      {
        icon: Brain,
        title: "Zero Repetition",
        desc: "What one agent learns, all inherit. Errors happen once — never twice."
      },
      {
        icon: RefreshCw,
        title: "Instant Switch",
        desc: "Claude today. Gemini tomorrow. Switch AI like changing clothes — without losing a single memory."
      },
      {
        icon: Shield,
        title: "Military Discipline",
        desc: "Rigid rules applied to all. Zero improvisation. Zero excuses. Guaranteed results."
      },
      {
        icon: Zap,
        title: "Total Scalability",
        desc: "Start alone. End with an army of agents. Makan72 grows with you."
      },
      {
        icon: Lock,
        title: "Absolute Privacy",
        desc: "Your data is yours. Local, encrypted memory under your total control."
      },
      {
        icon: TrendingUp,
        title: "Continuous Evolution",
        desc: "Every session makes the system smarter. Automatic cumulative learning."
      },
    ],
    ctaTitle: "Ready to Command?",
    ctaSubtitle: "Join the CEOs who no longer waste time repeating instructions.",
    ctaButton: "Get Started",
  },
};

export const aboutContent: Record<Language, AboutContent> = {
  PT: {
    badge: "Você é o CEO",
    title: "O Sistema que Coloca VOCÊ no Comando",
    p1: "O Makan72 é o sistema operacional para agentes de IA que transforma você no CEO da sua própria equipa de inteligência artificial.",
    p2: "Imagine: um carro de corrida onde você é o piloto. O chassis é fixo (o Makan72), mas os motores (agentes IA) são trocáveis. Claude, Gemini, Qwen — use o que quiser. A memória fica. O conhecimento acumula.",
    p3: "A diferença? O sistema aprende, não o agente. Cada erro, cada solução, cada preferência sua fica guardada para sempre. Quando troca de agente, o novo herda tudo. Você nunca começa do zero.",
    architecture: "A Sua Arquitetura de Poder",
    architectureDesc: "Você no topo. O Makan72 como camada de inteligência. Os agentes a executar.",
    benefits: "Os Seus Benefícios",
    benefitCards: [
      { title: "Memória Eterna", desc: "Erros e soluções ficam guardados para sempre. O sistema nunca esquece." },
      { title: "Liberdade Total", desc: "Use Claude, Gemini, Qwen ou qualquer outro. Troque quando quiser." },
      { title: "Disciplina Garantida", desc: "Regras rígidas previnem improvisos. Resultados consistentes." },
      { title: "Crescimento Ilimitado", desc: "Comece com um agente. Termine com cem. O Makan72 escala com você." },
      { title: "Transparência Absoluta", desc: "Tudo em ficheiros legíveis. Zero caixas pretas. Você controla tudo." },
      { title: "Custo Zero de Lock-in", desc: "Não dependa de nenhum fornecedor. A memória é sua." },
    ],
    nodes: [
      { label: "Você", sublabel: "(CEO)", action: "Comanda" },
      { label: "Makan72", sublabel: "", action: "Coordena" },
      { label: "Agentes IA", sublabel: "", action: "Executam" },
    ],
  },
  EN: {
    badge: "You are the CEO",
    title: "The System that Puts YOU in Command",
    p1: "Makan72 is the operating system for AI agents that transforms you into the CEO of your own artificial intelligence team.",
    p2: "Imagine: a race car where you are the driver. The chassis is fixed (Makan72), but the engines (AI agents) are interchangeable. Claude, Gemini, Qwen — use whatever you want. Memory stays. Knowledge accumulates.",
    p3: "The difference? The system learns, not the agent. Every error, every solution, every preference of yours is stored forever. When you switch agents, the new one inherits everything. You never start from zero.",
    architecture: "Your Architecture of Power",
    architectureDesc: "You at the top. Makan72 as the intelligence layer. Agents executing.",
    benefits: "Your Benefits",
    benefitCards: [
      { title: "Eternal Memory", desc: "Errors and solutions are stored forever. The system never forgets." },
      { title: "Total Freedom", desc: "Use Claude, Gemini, Qwen or any other. Switch whenever you want." },
      { title: "Guaranteed Discipline", desc: "Rigid rules prevent improvisation. Consistent results." },
      { title: "Unlimited Growth", desc: "Start with one agent. End with a hundred. Makan72 scales with you." },
      { title: "Absolute Transparency", desc: "Everything in readable files. Zero black boxes. You control everything." },
      { title: "Zero Lock-in Cost", desc: "Don't depend on any vendor. The memory is yours." },
    ],
    nodes: [
      { label: "You", sublabel: "(CEO)", action: "Command" },
      { label: "Makan72", sublabel: "", action: "Coordinate" },
      { label: "AI Agents", sublabel: "", action: "Execute" },
    ],
  },
};

// ============================================================================
// FUNÇÕES UTILITÁRIAS
// ============================================================================

/**
 * Obtém conteúdo da página principal baseado na linguagem
 */
export function getHomeContent(lang: Language): HomeContent {
  return homeContent[lang];
}

/**
 * Obtém features da página principal
 */
export function getHomeFeatures(lang: Language): Feature[] {
  return homeContent[lang].features;
}

/**
 * Obtém CTA content da página principal
 */
export function getHomeCTA(lang: Language) {
  const content = homeContent[lang];
  return {
    title: content.ctaTitle,
    subtitle: content.ctaSubtitle,
    button: content.ctaButton,
  };
}

/**
 * Obtém conteúdo da página "Sobre" baseado na linguagem
 */
export function getAboutContent(lang: Language): AboutContent {
  return aboutContent[lang];
}

/**
 * Obtém benefit cards da página "Sobre"
 */
export function getAboutBenefits(lang: Language) {
  return aboutContent[lang].benefitCards;
}

/**
 * Obtém nodes da arquitectura da página "Sobre"
 */
export function getAboutNodes(lang: Language) {
  return aboutContent[lang].nodes;
}

/**
 * Hook helper para uso com LanguageContext
 */
export function useTranslations(lang: Language) {
  return {
    home: homeContent[lang],
    about: aboutContent[lang],
    // Adicionar outras páginas aqui quando forem extraídas
  };
}
