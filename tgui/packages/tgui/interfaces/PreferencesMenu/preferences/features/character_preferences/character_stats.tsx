import { Box, NumberInput, Stack } from 'tgui-core/components';
import type { FeatureNumeric, FeatureValueProps } from '../base';

const characteristicIds = [
  'characteristic_strength',
  'characteristic_dexterity',
  'characteristic_perception',
  'characteristic_intelligence',
  'characteristic_spirit',
  'characteristic_charisma',
  'characteristic_luck',
];

const combatIds = [
  'combat_power_melee',
  'combat_heavy_weapons',
  'combat_grappling',
  'combat_toughness',
  'combat_fast_melee',
  'combat_light_weapons',
  'combat_acrobatics',
  'combat_evasion',
  'combat_precise_melee',
  'combat_throwing',
  'combat_weakspot_analysis',
  'combat_concentration',
  'combat_improved_code',
  'combat_fast_code',
  'combat_hacking',
  'combat_intelligence_composure',
  'combat_survival',
  'combat_endurance',
  'combat_athletics',
  'combat_compatibility',
  'combat_stealth',
  'combat_theft',
  'combat_inspiration',
  'combat_style',
];

const weaponIds = [
  'weapon_knives',
  'weapon_one_handed_chopping',
  'weapon_two_handed_chopping',
  'weapon_one_handed_piercing',
  'weapon_two_handed_piercing',
  'weapon_one_handed_slashing',
  'weapon_two_handed_slashing',
  'weapon_one_handed_blunt',
  'weapon_two_handed_blunt',
  'weapon_light_firearms',
  'weapon_medium_firearms',
  'weapon_heavy_firearms',
];

const professionalIds = [
  'professional_medicine',
  'professional_chemistry',
  'professional_electricity',
  'professional_construction',
  'professional_invention',
  'professional_analysis',
  'professional_mining',
  'professional_driving',
  'professional_cooking',
  'professional_gardening',
  'professional_music',
];

function getBudget(featureId: string) {
  if (characteristicIds.includes(featureId)) {
    return { ids: characteristicIds, max: 37 };
  }
  if (combatIds.includes(featureId)) {
    return { ids: combatIds, max: 20 };
  }
  if (weaponIds.includes(featureId)) {
    return { ids: weaponIds, max: 8 };
  }
  return { ids: professionalIds, max: 8 };
}

function PointBudgetInput(
  props: FeatureValueProps<
    number,
    number,
    { minimum: number; maximum: number; step: number }
  >,
) {
  const { value, serverData, handleSetValue, featureId, character_preferences } =
    props;
  const budget = getBudget(featureId);
  const used = budget.ids.reduce(
    (sum, id) => sum + Number(character_preferences.non_contextual[id] || 0),
    0,
  );
  const remaining = Math.max(0, budget.max - used);
  const maxForField = Math.min(
    serverData?.maximum ?? budget.max,
    Number(value) + remaining,
  );

  return (
    <Stack align="center">
      <Stack.Item grow>
        <NumberInput
          value={value}
          minValue={serverData?.minimum ?? 0}
          maxValue={maxForField}
          step={serverData?.step ?? 1}
          onChange={(value) => handleSetValue(value)}
        />
      </Stack.Item>
      <Stack.Item>
        <Box color={remaining > 0 ? 'label' : 'average'}>
          {remaining}/{budget.max}
        </Box>
      </Stack.Item>
    </Stack>
  );
}

const statFeature = (name: string): FeatureNumeric => ({
  name,
  component: PointBudgetInput,
});

export const characteristic_strength = statFeature('Strength');
export const characteristic_dexterity = statFeature('Dexterity');
export const characteristic_perception = statFeature('Accuracy');
export const characteristic_intelligence = statFeature('Intelligence');
export const characteristic_spirit = statFeature('Spirit');
export const characteristic_charisma = statFeature('Charisma');
export const characteristic_luck = statFeature('Luck');

export const combat_power_melee = statFeature('Power melee');
export const combat_heavy_weapons = statFeature('Heavy weapons');
export const combat_grappling = statFeature('Grappling');
export const combat_toughness = statFeature('Toughness');
export const combat_fast_melee = statFeature('Fast melee');
export const combat_light_weapons = statFeature('Light weapons');
export const combat_acrobatics = statFeature('Acrobatics');
export const combat_evasion = statFeature('Evasion');
export const combat_precise_melee = statFeature('Precise melee');
export const combat_throwing = statFeature('Throwing');
export const combat_weakspot_analysis = statFeature('Weakspot analysis');
export const combat_concentration = statFeature('Concentration');
export const combat_improved_code = statFeature('Improved code');
export const combat_fast_code = statFeature('Fast code');
export const combat_hacking = statFeature('Hacking');
export const combat_intelligence_composure = statFeature('Composure');
export const combat_survival = statFeature('Survival');
export const combat_endurance = statFeature('Endurance');
export const combat_athletics = statFeature('Athletics');
export const combat_compatibility = statFeature('Compatibility');
export const combat_stealth = statFeature('Stealth');
export const combat_theft = statFeature('Theft');
export const combat_inspiration = statFeature('Inspiration');
export const combat_style = statFeature('Style');

export const weapon_knives = statFeature('Knives');
export const weapon_one_handed_chopping = statFeature('One-handed chopping');
export const weapon_two_handed_chopping = statFeature('Two-handed chopping');
export const weapon_one_handed_piercing = statFeature('One-handed piercing');
export const weapon_two_handed_piercing = statFeature('Two-handed piercing');
export const weapon_one_handed_slashing = statFeature('One-handed slashing');
export const weapon_two_handed_slashing = statFeature('Two-handed slashing');
export const weapon_one_handed_blunt = statFeature('One-handed blunt');
export const weapon_two_handed_blunt = statFeature('Two-handed blunt');
export const weapon_light_firearms = statFeature('Light firearms');
export const weapon_medium_firearms = statFeature('Medium firearms');
export const weapon_heavy_firearms = statFeature('Heavy firearms');

export const professional_medicine = statFeature('Medicine');
export const professional_chemistry = statFeature('Chemistry');
export const professional_electricity = statFeature('Electricity');
export const professional_construction = statFeature('Construction');
export const professional_invention = statFeature('Invention');
export const professional_analysis = statFeature('Analysis');
export const professional_mining = statFeature('Mining');
export const professional_driving = statFeature('Driving');
export const professional_cooking = statFeature('Cooking');
export const professional_gardening = statFeature('Gardening');
export const professional_music = statFeature('Music');
