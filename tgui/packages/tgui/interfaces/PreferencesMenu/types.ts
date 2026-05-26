import type { BooleanLike } from 'tgui-core/react';

import type { sendAct } from '../../events/act';
import type {
  LoadoutCategory,
  LoadoutList,
  typePath,
} from './CharacterPreferences/loadout/base';
import type { Gender } from './preferences/gender';

export enum Food {
  Alcohol = 'ALCOHOL',
  Breakfast = 'BREAKFAST',
  Bugs = 'BUGS',
  Cloth = 'CLOTH',
  Dairy = 'DAIRY',
  Fried = 'FRIED',
  Fruit = 'FRUIT',
  Gore = 'GORE',
  Grain = 'GRAIN',
  Gross = 'GROSS',
  Junkfood = 'JUNKFOOD',
  Meat = 'MEAT',
  Nuts = 'NUTS',
  Oranges = 'ORANGES',
  Pineapple = 'PINEAPPLE',
  Raw = 'RAW',
  Seafood = 'SEAFOOD',
  Stone = 'STONE',
  Sugar = 'SUGAR',
  Toxic = 'TOXIC',
  Vegetables = 'VEGETABLES',
  Egg = 'EGG',
}

export enum JobPriority {
  Low = 1,
  Medium = 2,
  High = 3,
}

export type Name = {
  can_randomize: BooleanLike;
  explanation: string;
  group: string;
};

export type Species = {
  name: string;
  desc: string;
  lore: string[];
  icon: string;

  use_skintones: BooleanLike;
  sexes: BooleanLike;

  enabled_features: string[];

  perks: {
    positive: Perk[];
    negative: Perk[];
    neutral: Perk[];
  };

  diet?: {
    liked_food: Food[];
    disliked_food: Food[];
    toxic_food: Food[];
  };
};

export type Perk = {
  ui_icon: string;
  name: string;
  description: string;
};

export type Department = {
  head?: string;
};

export type RoleOutfitItem = {
  slot: string;
  item_name: string;
  item_type: string;
  icon?: string | null;
  icon_state?: string | null;
  source: string;
  guaranteed: BooleanLike;
  warning?: string | null;
};

export type Job = {
  description: string;
  department: string;
  supervisors?: string;
  paycheck?: number;
  paycheck_department?: string;
  total_positions?: number;
  spawn_positions?: number;
  outfit_items?: RoleOutfitItem[];
};

export type Quirk = {
  description: string;
  icon: string;
  name: string;
  value: number;
  customizable: boolean;
  customization_options?: string[];
};

export type QuirkInfo = {
  max_positive_quirks: number;
  quirk_info: Record<string, Quirk>;
  quirk_blacklist: string[][];
  points_enabled: boolean;
};

export type Personality = {
  name: string;
  description: string;
  pos_gameplay_description: string | null;
  neg_gameplay_description: string | null;
  neut_gameplay_description: string | null;
  path: typePath;
  groups: string[] | null;
};

export enum RandomSetting {
  AntagOnly = 1,
  Disabled = 2,
  Enabled = 3,
}

export enum JoblessRole {
  BeOverflow = 1,
  BeRandomJob = 2,
  ReturnToLobby = 3,
}

export enum GamePreferencesSelectedPage {
  Settings,
  Keybindings,
}

export const createSetPreference =
  (act: typeof sendAct, preference: string) => (value: unknown) => {
    act('set_preference', {
      preference,
      value,
    });
  };

export enum PrefsWindow {
  Character = 0,
  Game = 1,
  Keybindings = 2,
}

export type CharacterPreferencesData = {
  clothing: Record<string, string>;
  features: Record<string, string>;
  game_preferences: Record<string, unknown>;
  non_contextual: {
    random_body: RandomSetting;
    [otherKey: string]: unknown;
  };
  secondary_features: Record<string, unknown>;
  supplemental_features: Record<string, unknown>;
  manually_rendered_features: Record<string, string>;

  names: Record<string, string>;

  misc: {
    gender: Gender;
    joblessrole: JoblessRole;
    species: string;
    loadout_list: LoadoutList;
    job_clothes: BooleanLike;
  };

  randomization: Record<string, RandomSetting>;
};

export type CharacterSetupAttribute = {
  id: string;
  name: string;
  description: string;
};

export type CharacterSetupRuntimeAttribute = {
  value: number;
  min: number;
  max: number;
  super_threshold: number;
  editable: BooleanLike;
  disabled_reason?: string;
};

export type CharacterSetupPerk = {
  index: number;
  name: string;
  description: string;
  rank_descriptions?: string[];
  max_rank: number;
};

export type CharacterSetupRuntimePerk = {
  rank: number;
  can_increase: BooleanLike;
  can_decrease: BooleanLike;
};

export type CharacterSetupSkill = {
  id: typePath;
  name: string;
  title: string;
  description: string;
  attribute_id: string;
  kind: 'physical' | 'professional' | 'weapon' | string;
  point_pool: string;
  max_character_level: number;
  max_perk_rank: number;
  requires_sequential_perks: BooleanLike;
  giga_perk_name?: string;
  giga_perk_desc?: string;
  weapon_damage_bonus_per_level?: number;
  weapon_cooldown_reduction_per_level?: number;
  weapon_defense_break_bonus_per_level?: number;
  perks: CharacterSetupPerk[];
};

export type CharacterSetupRuntimeSkill = {
  level: number;
  spent_points: number;
  perks: Record<string, CharacterSetupRuntimePerk | number>;
  can_increase: BooleanLike;
  can_decrease: BooleanLike;
  editable: BooleanLike;
  disabled_reason?: string;
};

export type CharacterSetupImplantSlot = {
  id: string;
  name: string;
  zone: string;
  default_state: string;
};

export type CharacterSetupImplantMetrics = {
  chromity: number;
  chromity_max: number;
  overheat: number;
  overheat_floor: number;
  has_neural_implant: BooleanLike;
  editable: BooleanLike;
  disabled_reason?: string;
};

export type CharacterSetupRuntimeData = {
  attributes: Record<string, CharacterSetupRuntimeAttribute>;
  skills: Record<typePath, CharacterSetupRuntimeSkill>;
  level_points: number;
  skill_points: number;
  professional_skill_points: number;
  weapon_skill_points: number;
  implant_metrics: CharacterSetupImplantMetrics;
};

export type PreferencesMenuData = {
  character_preview_view: string;
  character_profiles: (string | null)[];

  character_preferences: CharacterPreferencesData;
  character_setup?: CharacterSetupRuntimeData;

  content_unlocked: BooleanLike;

  job_bans?: string[];
  job_days_left?: Record<string, number>;
  job_required_experience?: Record<
    string,
    {
      experience_type: string;
      required_playtime: number;
    }
  >;
  job_preferences: Record<string, JobPriority>;

  keybindings: Record<string, string[]>;
  overflow_role: string;
  default_quirk_balance: number;
  selected_quirks: string[];
  selected_personalities: typePath[] | null;
  max_personalities: number;
  mood_enabled: BooleanLike;
  species_disallowed_quirks: string[];

  antag_bans?: string[];
  antag_days_left?: Record<string, number>;
  selected_antags: string[];

  active_slot: number;
  name_to_use: string;
  window: PrefsWindow;

  // BANDASTATION ADDITION START
  pref_job_slots?: Record<string, number>;
  profile_index?: Record<string, string>;
  donator_level: number;
  tts_seed: string;
  tts_enabled: BooleanLike;

  incompatible_body_modifications: string[];
  applied_body_modifications: string[];
  manufacturers: Record<string, string[]>;
  selected_manufacturer: Record<string, string>;
  // BANDASTATION ADDITION END
};

// BANDASTATION ADDITION START
export type Seed = {
  name: string;
  value: string;
  category: string;
  gender: string;
  provider: string;
  donator_level: number;
};

export type TtsProvider = {
  name: string;
  is_enabled: BooleanLike;
};

export type TtsData = {
  providers: Array<TtsProvider>;
  seeds: Array<Seed>;
  phrases: string[];
};

export type BodyModification = {
  key: string;
  name: string;
  category: string;
  description: string;
  cost: number;
  manufacturers?: Record<string, string>;
  selectedManufacturer?: string;
};
// BANDASTATION ADDITION END

export type ServerData = {
  // BANDASTATION ADDITION START
  text_to_speech: TtsData;
  body_modifications: BodyModification[];
  // BANDASTATION ADDITION END
  jobs: {
    departments: Record<string, Department>;
    jobs: Record<string, Job>;
  };
  names: {
    types: Record<string, Name>;
  };
  quirks: QuirkInfo;
  personality: {
    personalities: Personality[];
    personality_incompatibilities: Record<string, string[]>;
  };
  random: {
    randomizable: string[];
  };
  loadout: {
    loadout_tabs: LoadoutCategory[];
  };
  character_setup?: {
    attributes: Record<string, CharacterSetupAttribute>;
    physical_skills: CharacterSetupSkill[];
    professional_skills: CharacterSetupSkill[];
    weapon_skills: CharacterSetupSkill[];
    implant_slots: CharacterSetupImplantSlot[];
  };
  species: Record<string, Species>;
  [otherKey: string]: unknown;
};
