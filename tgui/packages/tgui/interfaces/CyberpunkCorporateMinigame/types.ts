export type PipePart = { type: string; rotation: number };
export type MineCell = { open: boolean; flag: boolean; bomb: boolean; around: number };
export type DrCell = { color: string; kind: string } | null;
export type DrPill = { colors: string[] };

export type Paper = {
  product: string;
  price: number;
  budget: number;
  demand: number;
  profile: string;
};

export type CorporateMinigameData = {
  game: string;
  title: string;
  progress: number;
  errors: number;
  goal: number | string;
  completed: boolean;
  result: string;
  drBoard?: DrCell[][];
  currentPill?: DrPill;
  nextPill?: DrPill;
  colors?: string[];
  tripleBoard?: number[][];
  nextLevel?: number;
  pipeBoard?: PipePart[][];
  flowStarted?: boolean;
  program?: string[];
  robot?: { x: number; y: number; direction: string };
  stars?: Record<string, boolean>;
  tiles?: string[][];
  mineBoard?: MineCell[][];
  bombs?: number;
  paper?: Paper;
  activeCell?: number;
  activeUntil?: number;
};
