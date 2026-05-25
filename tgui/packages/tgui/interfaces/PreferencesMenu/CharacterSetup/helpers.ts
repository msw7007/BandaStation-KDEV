import type { sendAct } from '../../../events/act';
import type {
  CharacterPreferencesData,
  PreferencesMenuData,
  ServerData,
} from '../types';

type ServerPreferenceData = {
  choices?: string[];
  display_names?: Record<string, string>;
};

const preferenceBuckets: Array<keyof CharacterPreferencesData> = [
  'names',
  'non_contextual',
  'secondary_features',
  'supplemental_features',
  'features',
  'clothing',
  'manually_rendered_features',
];

export function getPreferenceValue(
  data: PreferencesMenuData,
  preference: string,
): unknown {
  for (const bucket of preferenceBuckets) {
    const values = data.character_preferences[bucket] as Record<
      string,
      unknown
    >;
    if (values && preference in values) {
      return values[preference];
    }
  }
  return undefined;
}

export function getServerPreference(
  serverData: ServerData | undefined,
  preference: string,
): ServerPreferenceData | undefined {
  return serverData?.[preference] as ServerPreferenceData | undefined;
}

export function getDisplayName(
  serverData: ServerData | undefined,
  preference: string,
  value: unknown,
): string {
  const serverPreference = getServerPreference(serverData, preference);
  const text = String(value ?? '');
  return serverPreference?.display_names?.[text] || text;
}

export function setPreference(
  act: typeof sendAct,
  preference: string,
  value: unknown,
) {
  act('set_preference', {
    preference,
    value,
  });
}

export function getChoiceOptions(
  serverData: ServerData | undefined,
  preference: string,
) {
  const serverPreference = getServerPreference(serverData, preference);
  return (serverPreference?.choices || []).map((choice) => ({
    displayText: serverPreference?.display_names?.[choice] || choice,
    value: choice,
  }));
}

export function flattenLoadoutCatalog(serverData: ServerData | undefined) {
  return serverData?.loadout.loadout_tabs.flatMap((category) =>
    category.contents.map((item) => ({
      ...item,
      category: category.name,
    })),
  );
}

export const attributeOrder = [
  'strength',
  'dexterity',
  'perception',
  'intelligence',
  'spirit',
  'charisma',
];

