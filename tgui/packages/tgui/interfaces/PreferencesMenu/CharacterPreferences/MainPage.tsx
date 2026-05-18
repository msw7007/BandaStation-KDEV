import { sortBy } from 'es-toolkit';
import { filter, map } from 'es-toolkit/compat';
import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { sendAct } from 'tgui/events/act';
import {
  Box,
  Button,
  Floating,
  Icon,
  ImageButton,
  Input,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import { capitalize, createSearch } from 'tgui-core/string';
import { CharacterPreview } from '../../common/CharacterPreview';
import { Preference } from '../components/Preference';
import { RandomizationButton } from '../components/RandomizationButton';
import { BodyModificationsPageInner } from '../preferences/BodyModificationsPage';
import { features } from '../preferences/features';
import {
  type FeatureChoicedServerData,
  FeatureValueInput,
} from '../preferences/features/base';
import { GENDERS, Gender } from '../preferences/gender';
import {
  createSetPreference,
  type PreferencesMenuData,
  RandomSetting,
  type ServerData,
} from '../types';
import { useRandomToggleState } from '../useRandomToggleState';
import { useServerPrefs } from '../useServerPrefs';
import { DeleteCharacterPopup } from './DeleteCharacterPopup';
import { AlternativeNames, NameInput } from './names';
import { VoicePageInner } from './VoicePage';

type CharacterControlsProps = {
  handleRotate: () => void;
  handleOpenSpecies: () => void;
  handleOpenAugmentations: () => void; // BANDASTATION ADD: Augmentations
  gender: Gender;
  setGender: (gender: Gender) => void;
  showGender: boolean;
  canDeleteCharacter: boolean;
  handleDeleteCharacter: () => void;
};

function CharacterControls(props: CharacterControlsProps) {
  return (
    <Stack className="PreferencesMenu__CharacterControls">
      <Button
        icon="undo"
        tooltip="Повернуть"
        tooltipPosition="top"
        onClick={props.handleRotate}
      />
      <Button
        icon="paw"
        tooltip="Вид"
        tooltipPosition="top"
        onClick={props.handleOpenSpecies}
      />
      {props.showGender && (
        <GenderButton gender={props.gender} handleSetGender={props.setGender} />
      )}
      <Button
        icon="robot"
        tooltip="Модификации тела"
        tooltipPosition="top"
        onClick={() => props.handleOpenAugmentations()}
      />
      <Button
        color="red"
        icon="trash"
        tooltip="Удалить персонажа"
        tooltipPosition="top"
        disabled={!props.canDeleteCharacter}
        onClick={props.handleDeleteCharacter}
      />
    </Stack>
  );
}

type GenderButtonProps = {
  handleSetGender: (gender: Gender) => void;
  gender: Gender;
};

function GenderButton(props: GenderButtonProps) {
  return (
    <Floating
      placement="top"
      content={
        <Stack className="PreferencesMenu__CharacterControls Gender">
          <Section>
            {Object.values(Gender).map((gender) => {
              return (
                <Button
                  key={gender}
                  selected={gender === props.gender}
                  icon={GENDERS[gender]?.icon || 'question'}
                  tooltip={GENDERS[gender]?.text || 'Кто ты, воин?'}
                  tooltipPosition="top"
                  onClick={() => {
                    props.handleSetGender(gender);
                  }}
                />
              );
            })}
          </Section>
        </Stack>
      }
    >
      <div>
        <Button
          icon={GENDERS[props.gender]?.icon || 'question'}
          tooltip="Пол"
          tooltipPosition="top"
        />
      </div>
    </Floating>
  );
}

type ChoicedSelectionProps = {
  name: string;
  catalog: FeatureChoicedServerData;
  selected: string;
  supplementalFeature?: string;
  supplementalValue?: unknown;
  onSelect: (value: string) => void;
};

function ChoicedSelection(props: ChoicedSelectionProps) {
  const { catalog, supplementalFeature, supplementalValue } = props;
  const [searchText, setSearchText] = useState('');

  if (!catalog.icons) {
    return <Box color="red">В предоставленном каталоге не было иконок!</Box>;
  }

  return (
    <Stack
      fill
      vertical
      g={0}
      className="PreferencesMenu__ChoicedSelection PreferencesMenu__CatalogPopup"
    >
      <Stack.Item>
        <Section
          fill
          title={`${capitalize(props.name)}`}
          buttons={
            supplementalFeature && (
              <FeatureValueInput
                shrink
                feature={features[supplementalFeature]}
                featureId={supplementalFeature}
                value={supplementalValue}
              />
            )
          }
        >
          <Input
            autoFocus
            fluid
            placeholder="Поиск..."
            onChange={setSearchText}
          />
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill scrollable noTopPadding>
          <Stack wrap>
            {searchInCatalog(searchText, catalog.icons).map(
              ([name, image], index) => {
                return (
                  <ImageButton
                    key={index}
                    asset={['preferences32x32', image]}
                    imageSize={32}
                    selected={name === props.selected}
                    tooltip={name}
                    tooltipPosition="right"
                    onClick={() => {
                      props.onSelect(name);
                    }}
                  />
                );
              },
            )}
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
}

function searchInCatalog(searchText = '', catalog: Record<string, string>) {
  let items = Object.entries(catalog);
  if (searchText) {
    items = filter(
      items,
      createSearch(searchText, ([name, _icon]) => name),
    );
  }
  return items;
}

type CatalogItem = {
  name: string;
  supplemental_feature?: string;
};

type MainFeatureProps = {
  catalog: FeatureChoicedServerData & CatalogItem;
  currentValue: string;
  handleSelect: (newClothing: string) => void;
  randomization?: RandomSetting;
  setRandomization: (newSetting: RandomSetting) => void;
};

function MainFeature(props: MainFeatureProps) {
  const { data } = useBackend<PreferencesMenuData>();
  const {
    catalog,
    currentValue,
    handleSelect,
    randomization,
    setRandomization,
  } = props;

  const supplementalFeature = catalog.supplemental_feature;
  return (
    <Floating
      stopChildPropagation
      placement="right-start"
      content={
        <ChoicedSelection
          name={catalog.name}
          catalog={catalog}
          selected={currentValue}
          supplementalFeature={supplementalFeature}
          supplementalValue={
            supplementalFeature &&
            data.character_preferences.supplemental_features[
              supplementalFeature
            ]
          }
          onSelect={handleSelect}
        />
      }
    >
      <ImageButton
        className="PreferencesMenu__MainFeature"
        asset={['preferences32x32', catalog.icons![currentValue]]}
        imageSize={48}
        buttons={
          randomization && (
            <RandomizationButton
              value={randomization}
              setValue={setRandomization}
            />
          )
        }
      />
    </Floating>
  );
}

const createSetRandomization =
  (preference: string) => (newSetting: RandomSetting) => {
    sendAct('set_random_preference', {
      preference,
      value: newSetting,
    });
  };

function sortPreferences(array: [string, unknown][]) {
  return sortBy(array, [([featureId]) => features[featureId]?.name]);
}

type PreferenceListProps = {
  preferences: Record<string, unknown>;
  randomizations: Record<string, RandomSetting>;
  orderedKeys?: string[];
};

export function PreferenceList(props: PreferenceListProps) {
  const { preferences, randomizations } = props;
  const preferenceEntries = Object.entries(preferences);
  const orderedEntries = props.orderedKeys
    ? [
        ...props.orderedKeys
          .filter((key) => key in preferences)
          .map((key) => [key, preferences[key]] as [string, unknown]),
        ...sortPreferences(
          preferenceEntries.filter(
            ([key]) => !props.orderedKeys?.includes(key),
          ),
        ),
      ]
    : sortPreferences(preferenceEntries);

  return preferenceEntries.length > 0 ? (
    <Stack vertical>
      {orderedEntries.map(
        ([featureId, value]) => {
          const feature = features[featureId];
          const randomSetting = randomizations[featureId];
          if (feature === undefined) {
            return (
              <Stack.Item key={featureId} bold>
                Компонент {featureId} не распознан.
              </Stack.Item>
            );
          }

          return (
            <Preference
              key={featureId}
              id={featureId}
              name={feature.name}
              description={feature.description}
              childrenClassName="Character"
            >
              <FeatureValueInput
                value={value}
                feature={feature}
                featureId={featureId}
              />
              {randomSetting && (
                <RandomizationButton
                  setValue={createSetRandomization(featureId)}
                  value={randomSetting}
                />
              )}
            </Preference>
          );
        },
      )}
    </Stack>
  ) : (
    <Stack fill vertical align="center" justify="center" my="auto" g={3}>
      <Stack.Item>
        <Icon name="face-sad-cry" size={7.5} color="blue" />
      </Stack.Item>
      <Stack.Item bold fontSize={1.25} color="label" textAlign="center">
        К сожалению, выбранная раса не имеет дополнительных параметров
        внешности.
      </Stack.Item>
    </Stack>
  );
}

export function getRandomization(
  preferences: Record<string, unknown>,
  serverData: ServerData | undefined,
  randomBodyEnabled: boolean,
): Record<string, RandomSetting> {
  const { data } = useBackend<PreferencesMenuData>();
  if (!randomBodyEnabled || !serverData) {
    return {};
  }

  return Object.fromEntries(
    map(
      filter(Object.keys(preferences), (key) =>
        serverData.random.randomizable.includes(key),
      ),
      (key) => [
        key,
        data.character_preferences.randomization[key] || RandomSetting.Disabled,
      ],
    ),
  );
}

type MainPageProps = {
  openSpecies: () => void;
};

const appearancePreferenceOrder = [
  'body_type',
  'body_height',
  'sprite_size',
  'sprite_width',
  'breasts_size',
  'butt_size',
  'belly_size',
  'lip_color',
  'tts_voice',
  'tts_voice_pitch',
  'tts_voice_color',
  'appearance_descriptor_1',
  'appearance_descriptor_2',
  'appearance_descriptor_3',
  'appearance_descriptor_4',
  'tattoo_head',
  'tattoo_torso',
  'tattoo_left_arm',
  'tattoo_right_arm',
  'tattoo_legs',
  'tattoo_color',
  'flavor_text',
  'hidden_flavor_text',
];

const genitalPreferenceOrder = [
  'penis_enabled',
  'penis_size',
  'testicles_size',
  'vagina_enabled',
  'vagina_size',
  'anus_size',
];

const characteristicPreferenceOrder = [
  'characteristic_strength',
  'characteristic_dexterity',
  'characteristic_perception',
  'characteristic_intelligence',
  'characteristic_spirit',
  'characteristic_charisma',
  'characteristic_luck',
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

const CHARACTERISTIC_BASE_VALUE = 5;
const CHARACTERISTIC_POINT_BUDGET = 5;
const CHARACTERISTIC_TOTAL_BUDGET =
  CHARACTERISTIC_BASE_VALUE * 7 + CHARACTERISTIC_POINT_BUDGET;
const WEAPON_POINT_BUDGET = 8;
const PROFESSIONAL_POINT_BUDGET = 8;
const PERK_CHECK_BONUS_PER_LEVEL = 2;
const PERK_EXPERIENCE_BONUS_PER_LEVEL = 5;
const PERK_WORK_SPEED_BONUS_PER_LEVEL = 1;
const PERK_QUALITY_BONUS_PER_LEVEL = 1;

const characteristicDefinitions = [
  {
    id: 'characteristic_dexterity',
    label: 'Dexterity',
    description:
      'Speed, fine control, evasive motion, light weapons and acrobatics.',
    statKey: 'dexterity',
    linkedSkills: [
      'combat_fast_melee',
      'combat_light_weapons',
      'combat_acrobatics',
      'combat_evasion',
    ],
    left: '4.8rem',
    top: '3.2rem',
  },
  {
    id: 'characteristic_strength',
    label: 'Strength',
    description:
      'Raw force, heavy gear, grappling, durability and direct melee pressure.',
    statKey: 'strength',
    linkedSkills: [
      'combat_power_melee',
      'combat_heavy_weapons',
      'combat_grappling',
      'combat_toughness',
    ],
    left: '9.6rem',
    top: '0',
  },
  {
    id: 'characteristic_perception',
    label: 'Accuracy',
    description:
      'Precision, weak-point reading, throwing and focused offensive timing.',
    statKey: 'perception',
    linkedSkills: [
      'combat_precise_melee',
      'combat_throwing',
      'combat_weakspot_analysis',
      'combat_concentration',
    ],
    left: '14.4rem',
    top: '3.2rem',
  },
  {
    id: 'characteristic_luck',
    label: 'Luck',
    description:
      'A global edge in uncertain checks. Luck is central and has no internal perk branch.',
    statKey: 'luck',
    linkedSkills: [],
    left: '9.6rem',
    top: '6.4rem',
  },
  {
    id: 'characteristic_intelligence',
    label: 'Intelligence',
    description:
      'Coding, hacking, fast problem solving and mental composure under pressure.',
    statKey: 'intelligence',
    linkedSkills: [
      'combat_improved_code',
      'combat_fast_code',
      'combat_hacking',
      'combat_intelligence_composure',
    ],
    left: '4.8rem',
    top: '9.6rem',
  },
  {
    id: 'characteristic_charisma',
    label: 'Charisma',
    description:
      'Style, social pressure, stealth, theft and the ability to inspire others.',
    statKey: 'charisma',
    linkedSkills: [
      'combat_stealth',
      'combat_theft',
      'combat_inspiration',
      'combat_style',
    ],
    left: '9.6rem',
    top: '12.8rem',
  },
  {
    id: 'characteristic_spirit',
    label: 'Spirit',
    description:
      'Survival, endurance, athletic drive and compatibility with body stress.',
    statKey: 'spirit',
    linkedSkills: [
      'combat_survival',
      'combat_endurance',
      'combat_athletics',
      'combat_compatibility',
    ],
    left: '14.4rem',
    top: '9.6rem',
  },
];

const skillDefinitions = [
  { id: 'combat_power_melee', label: 'Power melee', description: 'Direct force and pressure in close combat.', group: 'combat' },
  { id: 'combat_heavy_weapons', label: 'Heavy weapons', description: 'Control of heavy melee tools and oversized weapons.', group: 'combat' },
  { id: 'combat_grappling', label: 'Grappling', description: 'Clinches, holds, throws and body control.', group: 'combat' },
  { id: 'combat_toughness', label: 'Toughness', description: 'Staying useful while hurt, strained or pressured.', group: 'combat' },
  { id: 'combat_fast_melee', label: 'Fast melee', description: 'Quick close-range attacks and tempo shifts.', group: 'combat' },
  { id: 'combat_light_weapons', label: 'Light weapons', description: 'Short blades, light tools and quick weapon handling.', group: 'combat' },
  { id: 'combat_acrobatics', label: 'Acrobatics', description: 'Mobility, balance and aggressive movement.', group: 'combat' },
  { id: 'combat_evasion', label: 'Evasion', description: 'Dodging, disengaging and slipping pressure.', group: 'combat' },
  { id: 'combat_precise_melee', label: 'Precise melee', description: 'Accurate strikes and clean targeting in melee.', group: 'combat' },
  { id: 'combat_throwing', label: 'Throwing', description: 'Thrown weapons, arcs and target leading.', group: 'combat' },
  { id: 'combat_weakspot_analysis', label: 'Weakspot analysis', description: 'Reading armor, injuries and exposed openings.', group: 'combat' },
  { id: 'combat_concentration', label: 'Concentration', description: 'Keeping aim and action quality under stress.', group: 'combat' },
  { id: 'combat_improved_code', label: 'Improved code', description: 'Cleaner code interactions and more reliable systems work.', group: 'combat' },
  { id: 'combat_fast_code', label: 'Fast code', description: 'Rapid system interaction and shorter execution windows.', group: 'combat' },
  { id: 'combat_hacking', label: 'Hacking', description: 'Intrusion, bypass and hostile system control.', group: 'combat' },
  {
    id: 'combat_intelligence_composure',
    label: 'Composure',
    description: 'Mental control when the situation becomes chaotic.',
    group: 'combat',
  },
  { id: 'combat_survival', label: 'Survival', description: 'Keeping yourself alive in hostile conditions.', group: 'combat' },
  { id: 'combat_endurance', label: 'Endurance', description: 'Long effort, fatigue tolerance and sustained pressure.', group: 'combat' },
  { id: 'combat_athletics', label: 'Athletics', description: 'Running, climbing, jumping and full-body work.', group: 'combat' },
  { id: 'combat_compatibility', label: 'Compatibility', description: 'Body adaptation and stability under augmentation stress.', group: 'combat' },
  { id: 'combat_stealth', label: 'Stealth', description: 'Quiet movement and staying unnoticed.', group: 'combat' },
  { id: 'combat_theft', label: 'Theft', description: 'Taking, hiding and manipulating small valuables.', group: 'combat' },
  { id: 'combat_inspiration', label: 'Inspiration', description: 'Lifting group momentum and keeping allies moving.', group: 'combat' },
  { id: 'combat_style', label: 'Style', description: 'Presence, intimidation and performative confidence.', group: 'combat' },
] as const;

const weaponSkillDefinitions = [
  { id: 'weapon_knives', label: 'Knives' },
  { id: 'weapon_one_handed_chopping', label: 'One-handed chopping' },
  { id: 'weapon_two_handed_chopping', label: 'Two-handed chopping' },
  { id: 'weapon_one_handed_piercing', label: 'One-handed piercing' },
  { id: 'weapon_two_handed_piercing', label: 'Two-handed piercing' },
  { id: 'weapon_one_handed_slashing', label: 'One-handed slashing' },
  { id: 'weapon_two_handed_slashing', label: 'Two-handed slashing' },
  { id: 'weapon_one_handed_blunt', label: 'One-handed blunt' },
  { id: 'weapon_two_handed_blunt', label: 'Two-handed blunt' },
  { id: 'weapon_light_firearms', label: 'Light firearms' },
  { id: 'weapon_medium_firearms', label: 'Medium firearms' },
  { id: 'weapon_heavy_firearms', label: 'Heavy firearms' },
] as const;

const professionalSkillDefinitions = [
  {
    id: 'professional_medicine',
    label: 'Medicine',
    description: 'Treatment, diagnosis, field stabilization and surgery support.',
    group: 'professional',
    left: '16%',
    top: '9%',
  },
  {
    id: 'professional_chemistry',
    label: 'Chemistry',
    description: 'Reagents, reactions, mixtures and safe handling of substances.',
    group: 'professional',
    left: '27%',
    top: '0%',
  },
  {
    id: 'professional_electricity',
    label: 'Electricity',
    description: 'Power systems, wiring, devices and electrical repair.',
    group: 'professional',
    left: '73%',
    top: '0%',
  },
  {
    id: 'professional_construction',
    label: 'Construction',
    description: 'Structures, repairs, assembly and heavy station work.',
    group: 'professional',
    left: '84%',
    top: '9%',
  },
  {
    id: 'professional_invention',
    label: 'Invention',
    description: 'Research, prototyping and unusual technical solutions.',
    group: 'professional',
    left: '14%',
    top: '32%',
  },
  {
    id: 'professional_analysis',
    label: 'Analysis',
    description: 'Reading data, evidence, anomalies and indirect signs.',
    group: 'professional',
    left: '86%',
    top: '32%',
  },
  {
    id: 'professional_mining',
    label: 'Mining',
    description: 'Extraction, prospecting and hazardous industrial labor.',
    group: 'professional',
    left: '16%',
    top: '55%',
  },
  {
    id: 'professional_driving',
    label: 'Driving',
    description: 'Vehicle handling, maneuvering and transport control.',
    group: 'professional',
    left: '84%',
    top: '55%',
  },
  {
    id: 'professional_cooking',
    label: 'Cooking',
    description: 'Food preparation, kitchen flow and ingredient handling.',
    group: 'professional',
    left: '29%',
    top: '73%',
  },
  {
    id: 'professional_gardening',
    label: 'Gardening',
    description: 'Hydroponics, plant care and harvest quality.',
    group: 'professional',
    left: '50%',
    top: '77%',
  },
  {
    id: 'professional_music',
    label: 'Music',
    description: 'Performance, rhythm, audience control and artistic skill.',
    group: 'professional',
    left: '71%',
    top: '73%',
  },
] as const;

const characteristicIds = characteristicDefinitions.map(({ id }) => id);
const weaponSkillIds = weaponSkillDefinitions.map(({ id }) => id);
const professionalSkillIds = professionalSkillDefinitions.map(({ id }) => id);

type TooltipInfo = {
  title: string;
  body: string;
};

function getPreferenceNumber(
  preferences: Record<string, unknown>,
  key: string,
  fallback = 0,
): number {
  return Number(preferences[key] ?? fallback);
}

function getUsedPoints(
  preferences: Record<string, unknown>,
  keys: readonly string[],
): number {
  return keys.reduce((sum, key) => sum + getPreferenceNumber(preferences, key), 0);
}

function getPerkEffectText(level: number) {
  return [
    `+${level * PERK_CHECK_BONUS_PER_LEVEL}% skill checks`,
    `+${level * PERK_EXPERIENCE_BONUS_PER_LEVEL}% skill experience`,
    `+${level * PERK_WORK_SPEED_BONUS_PER_LEVEL}% work speed`,
    `+${level * PERK_QUALITY_BONUS_PER_LEVEL}% result quality`,
  ].join(', ');
}

function getPerkTooltip(
  skill: { label: string; description: string },
  level: number,
) {
  return {
    title: `${skill.label} ${level}`,
    body: `${skill.description} ${getPerkEffectText(level)}.`,
  };
}

type HexControlProps = {
  label: string;
  value: number;
  onClick?: () => void;
  onMinus: () => void;
  onPlus: () => void;
  onHover?: () => void;
  onUnhover?: () => void;
  selected?: boolean;
  small?: boolean;
};

function HexControl(props: HexControlProps) {
  const { label, value, selected, small } = props;
  const size = small ? '4.9rem' : '6.4rem';
  return (
    <div
      style={{
        alignItems: 'center',
        aspectRatio: '1 / 0.92',
        background: selected
          ? 'linear-gradient(145deg, rgba(35,255,245,0.24), rgba(255,45,72,0.18))'
          : 'linear-gradient(145deg, rgba(255,45,72,0.16), rgba(35,255,245,0.05))',
        border: selected
          ? '1px solid rgba(35,255,245,0.92)'
          : '1px solid rgba(255,55,68,0.52)',
        boxShadow: selected
          ? '0 0 22px rgba(35,255,245,0.24), inset 0 0 28px rgba(255,45,72,0.13)'
          : 'inset 0 0 22px rgba(255,45,72,0.09)',
        clipPath:
          'polygon(24% 0%, 76% 0%, 100% 50%, 76% 100%, 24% 100%, 0% 50%)',
        cursor: props.onClick ? 'pointer' : 'default',
        display: 'flex',
        flexDirection: 'column',
        height: size,
        justifyContent: 'center',
        padding: small ? '0.4rem 0.55rem' : '0.6rem 0.75rem',
        position: 'relative',
        textAlign: 'center',
        width: size,
      }}
      onClick={props.onClick}
      onMouseEnter={props.onHover}
      onMouseLeave={props.onUnhover}
    >
      <Box
        bold
        color={selected ? 'blue' : 'label'}
        fontSize={small ? 0.68 : 0.76}
        style={{ textTransform: 'uppercase' }}
      >
        {label}
      </Box>
      <Box bold fontSize={small ? 1.1 : 1.42} mt={0.25}>
        {value}
      </Box>
      <div
        style={{
          display: 'flex',
          gap: 0,
          justifyContent: 'center',
          marginTop: small ? '0.1rem' : '0.2rem',
        }}
      >
        <button
          style={{
            background: 'rgba(5, 18, 24, 0.92)',
            border: '1px solid rgba(35,255,245,0.72)',
            color: '#5ffcff',
            cursor: 'pointer',
            height: small ? '1rem' : '1.15rem',
            lineHeight: small ? '0.75rem' : '0.9rem',
            padding: 0,
            width: small ? '1rem' : '1.15rem',
          }}
          onClick={(event) => {
            event.stopPropagation();
            props.onMinus();
          }}
        >
          -
        </button>
        <button
          style={{
            background: 'rgba(5, 18, 24, 0.92)',
            border: '1px solid rgba(35,255,245,0.72)',
            borderLeft: 0,
            color: '#5ffcff',
            cursor: 'pointer',
            height: small ? '1rem' : '1.15rem',
            lineHeight: small ? '0.75rem' : '0.9rem',
            padding: 0,
            width: small ? '1rem' : '1.15rem',
          }}
          onClick={(event) => {
            event.stopPropagation();
            props.onPlus();
          }}
        >
          +
        </button>
      </div>
    </div>
  );
}

type SkillAdjustRowProps = {
  label: string;
  value: number;
  onMinus: () => void;
  onPlus: () => void;
};

function SkillAdjustRow(props: SkillAdjustRowProps) {
  return (
    <Stack align="center" g={1}>
      <Stack.Item grow>{props.label}</Stack.Item>
      <Stack.Item bold color="label" width="1.4rem" textAlign="center">
        {props.value}
      </Stack.Item>
      <Stack.Item>
        <Button compact onClick={props.onMinus}>
          -
        </Button>
        <Button compact onClick={props.onPlus}>
          +
        </Button>
      </Stack.Item>
    </Stack>
  );
}

type PerkNodeProps = {
  level: number;
  selected: boolean;
  disabled: boolean;
  onClick: () => void;
  onHover?: () => void;
  onUnhover?: () => void;
};

function PerkNode(props: PerkNodeProps) {
  return (
    <button
      disabled={props.disabled}
      style={{
        background: props.selected
          ? 'linear-gradient(145deg, rgba(35,255,245,0.38), rgba(255,45,72,0.22))'
          : 'linear-gradient(145deg, rgba(255,45,72,0.13), rgba(8,18,25,0.96))',
        border: props.selected
          ? '1px solid rgba(35,255,245,0.95)'
          : '1px solid rgba(255,55,68,0.48)',
        boxShadow: props.selected
          ? '0 0 12px rgba(35,255,245,0.22), inset 0 0 12px rgba(35,255,245,0.12)'
          : 'inset 0 0 10px rgba(255,45,72,0.08)',
        clipPath:
          'polygon(24% 0%, 76% 0%, 100% 50%, 76% 100%, 24% 100%, 0% 50%)',
        color: props.disabled ? 'rgba(120,145,150,0.55)' : '#bff9ff',
        cursor: props.disabled ? 'default' : 'pointer',
        fontWeight: 900,
        height: '2.6rem',
        lineHeight: '2.28rem',
        opacity: props.disabled ? 0.55 : 1,
        padding: 0,
        textAlign: 'center',
        width: '2.6rem',
      }}
      onClick={props.onClick}
      onMouseEnter={props.onHover}
      onMouseLeave={props.onUnhover}
    >
      {props.level}
    </button>
  );
}

function StatsTooltip(props: { info: TooltipInfo | null }) {
  if (!props.info) {
    return null;
  }

  return (
    <div
      style={{
        background:
          'linear-gradient(135deg, rgba(5,14,20,0.96), rgba(55,5,15,0.92))',
        border: '1px solid rgba(35,255,245,0.65)',
        bottom: '0.75rem',
        boxShadow:
          '0 0 18px rgba(35,255,245,0.18), inset 0 0 20px rgba(255,45,72,0.12)',
        left: '0.75rem',
        maxWidth: '24rem',
        padding: '0.55rem 0.75rem',
        pointerEvents: 'none',
        position: 'absolute',
        zIndex: 5,
      }}
    >
      <Box bold color="blue" fontSize={0.9} mb={0.3}>
        {props.info.title}
      </Box>
      <Box color="label" fontSize={0.82}>
        {props.info.body}
      </Box>
    </div>
  );
}

function CharacterStatsPanel() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const preferences = data.character_preferences.non_contextual;
  const [selectedBranch, setSelectedBranch] = useState<
    { kind: 'characteristic'; id: string } | null
  >(null);
  const [tooltipInfo, setTooltipInfo] = useState<TooltipInfo | null>(null);

  const selectedCharacteristic = characteristicDefinitions.find(
    ({ id }) => selectedBranch?.kind === 'characteristic' && id === selectedBranch.id,
  );
  const characteristicUsed = characteristicIds.reduce(
    (sum, key) =>
      sum + getPreferenceNumber(preferences, key, CHARACTERISTIC_BASE_VALUE),
    0,
  );
  const weaponUsed = getUsedPoints(preferences, weaponSkillIds);
  const professionalUsed = getUsedPoints(preferences, professionalSkillIds);
  const attributePointsLeft = Math.max(
    0,
    CHARACTERISTIC_TOTAL_BUDGET - characteristicUsed,
  );

  const setPreference = (key: string, value: number) => {
    if (!(key in preferences)) {
      return;
    }
    createSetPreference(act, key)(value);
  };

  const getCharacteristicValue = (key: string) =>
    getPreferenceNumber(preferences, key, CHARACTERISTIC_BASE_VALUE);

  const getBranchUsed = (characteristic: (typeof characteristicDefinitions)[number]) =>
    getUsedPoints(preferences, characteristic.linkedSkills);

  const adjustCharacteristic = (
    characteristic: (typeof characteristicDefinitions)[number],
    delta: number,
  ) => {
    const currentValue = getCharacteristicValue(characteristic.id);
    const nextValue = Math.min(20, Math.max(1, currentValue + delta));
    if (nextValue === currentValue || nextValue < getBranchUsed(characteristic)) {
      return;
    }

    const usedWithoutCurrent = characteristicUsed - currentValue;
    if (usedWithoutCurrent + nextValue > CHARACTERISTIC_TOTAL_BUDGET) {
      return;
    }

    setPreference(characteristic.id, nextValue);
  };

  const setBranchSkillLevel = (
    characteristic: (typeof characteristicDefinitions)[number],
    key: string,
    nextValue: number,
  ) => {
    const currentValue = getPreferenceNumber(preferences, key);
    nextValue = Math.min(6, Math.max(0, nextValue));
    const branchLimit = getCharacteristicValue(characteristic.id);
    const usedWithoutCurrent = getBranchUsed(characteristic) - currentValue;
    if (nextValue === currentValue || usedWithoutCurrent + nextValue > branchLimit) {
      return;
    }

    setPreference(key, nextValue);
  };

  const adjustBudgetSkill = (
    key: string,
    delta: number,
    keys: readonly string[],
    budget: number,
    maximum: number,
  ) => {
    const currentValue = getPreferenceNumber(preferences, key);
    const nextValue = Math.min(maximum, Math.max(0, currentValue + delta));
    const usedWithoutCurrent = getUsedPoints(preferences, keys) - currentValue;
    if (nextValue === currentValue || usedWithoutCurrent + nextValue > budget) {
      return;
    }

    setPreference(key, nextValue);
  };

  const renderSkillList = (
    title: string,
    definitions: readonly { id: string; label: string }[],
    keys: readonly string[],
    used: number,
    budget: number,
    maximum: number,
  ) => {
    return (
      <Section
        fill
        title={title}
        buttons={
          <Box color={used < budget ? 'good' : 'average'}>
            {budget - used}/{budget}
          </Box>
        }
      >
        <Stack vertical g={0.5}>
          {definitions.map(({ id, label }) => (
            <SkillAdjustRow
              key={id}
              label={label}
              value={getPreferenceNumber(preferences, id)}
              onMinus={() => adjustBudgetSkill(id, -1, keys, budget, maximum)}
              onPlus={() => adjustBudgetSkill(id, 1, keys, budget, maximum)}
            />
          ))}
        </Stack>
      </Section>
    );
  };

  const perkHoneycombPositions = [
    { left: '0', top: '0' },
    { left: '1.95rem', top: '1.3rem' },
    { left: '0', top: '2.6rem' },
    { left: '1.95rem', top: '3.9rem' },
    { left: '0', top: '5.2rem' },
    { left: '1.95rem', top: '6.5rem' },
  ];

  const renderPerkHoneycomb = (
    skill: { id: string; label: string; description: string },
    value: number,
    disabledForLevel: (level: number) => boolean,
    setLevel: (level: number) => void,
  ) => (
    <div key={skill.id} style={{ minWidth: 0, textAlign: 'center' }}>
      <Box
        bold
        color="label"
        fontSize={0.78}
        mb={0.4}
        style={{
          minHeight: '1.9rem',
          textTransform: 'uppercase',
        }}
      >
        {skill.label}
      </Box>
      <div
        style={{
          height: '9.1rem',
          margin: '0 auto',
          position: 'relative',
          width: '4.55rem',
        }}
      >
        {[1, 2, 3, 4, 5, 6].map((level) => {
          const selected = value >= level;
          const nextValue = selected ? level - 1 : level;
          const position = perkHoneycombPositions[level - 1];

          return (
            <div
              key={level}
              style={{
                left: position.left,
                position: 'absolute',
                top: position.top,
              }}
            >
              <PerkNode
                level={level}
                selected={selected}
                disabled={!selected && disabledForLevel(level)}
                onClick={() => setLevel(nextValue)}
                onHover={() => setTooltipInfo(getPerkTooltip(skill, level))}
                onUnhover={() => setTooltipInfo(null)}
              />
            </div>
          );
        })}
      </div>
    </div>
  );

  const selectedTitle = selectedCharacteristic?.label || 'Characteristics';

  return (
    <Stack vertical g={2}>
      <Section
        title={selectedTitle}
        buttons={
          selectedBranch ? (
            <Button
              compact
              icon="arrow-left"
              onClick={() => {
                setSelectedBranch(null);
                setTooltipInfo(null);
              }}
            />
          ) : (
            <Stack align="center" g={1}>
              <Stack.Item color={attributePointsLeft > 0 ? 'good' : 'average'}>
                AP {attributePointsLeft}
              </Stack.Item>
              <Stack.Item
                color={
                  professionalUsed < PROFESSIONAL_POINT_BUDGET
                    ? 'good'
                    : 'average'
                }
              >
                PP {PROFESSIONAL_POINT_BUDGET - professionalUsed}
              </Stack.Item>
            </Stack>
          )
        }
      >
        {!selectedBranch && (
          <Stack vertical g={1.25}>
            <Stack.Item>
              <div
                style={{
                  background:
                    'radial-gradient(circle at 50% 39%, rgba(35,255,245,0.12), rgba(255,45,72,0.08) 30%, rgba(5,8,14,0.05) 63%)',
                  margin: '0 auto',
                  width: '25.6rem',
                  height: '19.2rem',
                  position: 'relative',
                }}
              >
                {characteristicDefinitions.map((characteristic) => (
                  <div
                    key={characteristic.id}
                    style={{
                      left: characteristic.left,
                      position: 'absolute',
                      top: characteristic.top,
                    }}
                  >
                    <HexControl
                      label={characteristic.label}
                      value={getCharacteristicValue(characteristic.id)}
                      onClick={
                        characteristic.linkedSkills.length
                          ? () =>
                              setSelectedBranch({
                                kind: 'characteristic',
                                id: characteristic.id,
                              })
                          : undefined
                      }
                      onMinus={() => adjustCharacteristic(characteristic, -1)}
                      onPlus={() => adjustCharacteristic(characteristic, 1)}
                      onHover={() =>
                        setTooltipInfo({
                          title: characteristic.label,
                          body: characteristic.description,
                        })
                      }
                      onUnhover={() => setTooltipInfo(null)}
                      selected={characteristic.id === 'characteristic_luck'}
                    />
                  </div>
                ))}
                <StatsTooltip info={tooltipInfo} />
              </div>
            </Stack.Item>
            <Stack.Item>
              <Stack align="stretch" g={1.25}>
                <Stack.Item basis="50%">
                  {renderSkillList(
                    'Weapon mastery',
                    weaponSkillDefinitions,
                    weaponSkillIds,
                    weaponUsed,
                    WEAPON_POINT_BUDGET,
                    6,
                  )}
                </Stack.Item>
                <Stack.Item basis="50%">
                  {renderSkillList(
                    'Professional',
                    professionalSkillDefinitions,
                    professionalSkillIds,
                    professionalUsed,
                    PROFESSIONAL_POINT_BUDGET,
                    6,
                  )}
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        )}
        {selectedCharacteristic && (
          <div style={{ minHeight: '29rem', position: 'relative' }}>
            <Stack vertical>
              <Stack.Item>
                <Box color="label">
                  {getBranchUsed(selectedCharacteristic)}/
                  {getCharacteristicValue(selectedCharacteristic.id)}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <div
                  style={{
                    display: 'grid',
                    gap: '2rem',
                    gridTemplateColumns: 'repeat(4, minmax(7.2rem, 1fr))',
                    marginTop: '1.6rem',
                  }}
                >
                  {selectedCharacteristic.linkedSkills.map((id) => {
                    const skill = skillDefinitions.find((entry) => entry.id === id);
                    if (!skill) {
                      return null;
                    }
                    const value = getPreferenceNumber(preferences, id);
                    const branchLimit = getCharacteristicValue(
                      selectedCharacteristic.id,
                    );
                    const usedWithoutCurrent =
                      getBranchUsed(selectedCharacteristic) - value;

                    return renderPerkHoneycomb(
                      skill,
                      value,
                      (level) => usedWithoutCurrent + level > branchLimit,
                      (level) =>
                        setBranchSkillLevel(selectedCharacteristic, id, level),
                    );
                  })}
                </div>
              </Stack.Item>
            </Stack>
            <StatsTooltip info={tooltipInfo} />
          </div>
        )}
      </Section>
    </Stack>
  );
}

function pickPreferences(
  source: Record<string, unknown>,
  keys: string[],
): Record<string, unknown> {
  return Object.fromEntries(
    keys.filter((key) => key in source).map((key) => [key, source[key]]),
  );
}

function omitPreferences(
  source: Record<string, unknown>,
  keys: string[],
): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(source).filter(([key]) => !keys.includes(key)),
  );
}

export function MainPage(props: MainPageProps) {
  const { act, data } = useBackend<PreferencesMenuData>();

  const [deleteCharacterPopupOpen, setDeleteCharacterPopupOpen] =
    useState(false);
  const [randomToggleEnabled] = useRandomToggleState();
  const [selectedBlock, setSelectedBlock] = useState<
    'info' | 'appearance' | 'stats' | 'augmentations'
  >('info');

  const serverData = useServerPrefs();

  const currentSpeciesData =
    serverData?.species[data.character_preferences.misc.species];

  const contextualPreferences =
    data.character_preferences.secondary_features || [];

  const mainFeatures = [
    ...Object.entries(data.character_preferences.clothing ?? {}),
    ...Object.entries(data.character_preferences.features ?? {}),
  ];

  const randomBodyEnabled =
    data.character_preferences.non_contextual.random_body !==
      RandomSetting.Disabled || randomToggleEnabled;

  const randomizationOfMainFeatures = getRandomization(
    Object.fromEntries(mainFeatures),
    serverData,
    randomBodyEnabled,
  );

  const nonContextualPreferences = {
    ...data.character_preferences.non_contextual,
  };

  if (randomBodyEnabled) {
    nonContextualPreferences.random_species =
      data.character_preferences.randomization.species;
    // BANDASTATION ADDITION START - TTS
    nonContextualPreferences.random_tts_seed =
      data.character_preferences.randomization.tts_seed;
    // BANDASTATION ADDITION END - TTS
  } else {
    delete nonContextualPreferences.random_name;
  }

  const Character = (
    <Section fill className="PreferencesMenu__Character PreferencesMenu__CharacterPreviewCard">
      <Stack fill vertical>
        <Stack.Item>
          <CharacterControls
            gender={data.character_preferences.misc.gender}
            handleOpenSpecies={props.openSpecies}
            handleOpenAugmentations={() => setSelectedBlock('augmentations')}
            handleRotate={() => {
              act('rotate');
            }}
            setGender={createSetPreference(act, 'gender')}
            showGender={currentSpeciesData ? !!currentSpeciesData.sexes : true}
            canDeleteCharacter={
              Object.values(data.character_profiles).filter((name) => !!name)
                .length > 1
            }
            handleDeleteCharacter={() => setDeleteCharacterPopupOpen(true)}
          />
        </Stack.Item>
        <Stack.Item grow className="PreferencesMenu__PreviewFrame">
          <CharacterPreview height="100%" id={data.character_preview_view} />
        </Stack.Item>
        <Stack.Item>
          <NameInput
            large
            canRandomize
            name={data.character_preferences.names[data.name_to_use]}
            nameType={data.name_to_use}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );

  const MainFeatures = (
    <Section className="PreferencesMenu__FeaturesRail" fill scrollable>
      <Stack vertical direction="column-reverse">
        {mainFeatures.map(([clothingKey, clothing]) => {
          const catalog = serverData?.[
            clothingKey
          ] as FeatureChoicedServerData & {
            name: string;
          };

          return (
            <Stack.Item key={clothingKey}>
              {!catalog ? (
                <ImageButton imageSize={48} />
              ) : (
                <MainFeature
                  catalog={catalog}
                  currentValue={clothing}
                  handleSelect={createSetPreference(act, clothingKey)}
                  randomization={randomizationOfMainFeatures[clothingKey]}
                  setRandomization={createSetRandomization(clothingKey)}
                />
              )}
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );

  const appearancePreferences = {
    ...pickPreferences(nonContextualPreferences, appearancePreferenceOrder),
    ...contextualPreferences,
    ...pickPreferences(nonContextualPreferences, genitalPreferenceOrder),
  };
  const appearanceOrderedKeys = [
    ...appearancePreferenceOrder,
    ...Object.keys(contextualPreferences),
    ...genitalPreferenceOrder,
  ];
  const infoPreferences = omitPreferences(nonContextualPreferences, [
    ...appearancePreferenceOrder,
    ...genitalPreferenceOrder,
    ...characteristicPreferenceOrder,
  ]);

  const DetailsPanel = (
    <Section
      fill
      scrollable
      title={
        <Tabs>
          <Tabs.Tab
            icon="address-card"
            selected={selectedBlock === 'info'}
            onClick={() => setSelectedBlock('info')}
          >
            Info
          </Tabs.Tab>
          <Tabs.Tab
            icon="user"
            selected={selectedBlock === 'appearance'}
            onClick={() => setSelectedBlock('appearance')}
          >
            Appearance
          </Tabs.Tab>
          <Tabs.Tab
            icon="chart-line"
            selected={selectedBlock === 'stats'}
            onClick={() => setSelectedBlock('stats')}
          >
            Stats
          </Tabs.Tab>
          <Tabs.Tab
            icon="robot"
            selected={selectedBlock === 'augmentations'}
            onClick={() => setSelectedBlock('augmentations')}
          >
            Augmentations
          </Tabs.Tab>
        </Tabs>
      }
      className="PreferencesMenu__InfoPanel"
    >
      {selectedBlock === 'info' && (
        <PreferenceList
          preferences={infoPreferences}
          randomizations={getRandomization(
            infoPreferences,
            serverData,
            randomBodyEnabled,
          )}
        />
      )}
      {selectedBlock === 'appearance' && (
        <Stack vertical>
          <Stack.Item>
            <PreferenceList
              preferences={appearancePreferences}
              orderedKeys={appearanceOrderedKeys}
              randomizations={getRandomization(
                appearancePreferences,
                serverData,
                randomBodyEnabled,
              )}
            />
          </Stack.Item>
          {!!data.tts_enabled && serverData && (
            <Stack.Item>
              <VoicePageInner text_to_speech={serverData.text_to_speech} />
            </Stack.Item>
          )}
        </Stack>
      )}
      {selectedBlock === 'stats' && <CharacterStatsPanel />}
      {selectedBlock === 'augmentations' &&
        (serverData ? (
          <BodyModificationsPageInner
            bodyModification={serverData.body_modifications}
          />
        ) : (
          <Icon name="spinner" spin />
        ))}
    </Section>
  );

  return (
    <Stack fill className="PreferencesMenu__MainLayout" g={1}>
      {deleteCharacterPopupOpen && (
        <DeleteCharacterPopup
          close={() => setDeleteCharacterPopupOpen(false)}
        />
      )}
      <Stack.Item className="PreferencesMenu__PreviewColumn" basis="27%">
        <Stack fill vertical>
          <Stack.Item basis="53%">{Character}</Stack.Item>
          <Stack.Item grow>
            <div className="PreferencesMenu__AltNamesCard">
              <AlternativeNames names={data.character_preferences.names} />
            </div>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item className="PreferencesMenu__RailColumn" basis="7%">
        {MainFeatures}
      </Stack.Item>
      <Stack.Item className="PreferencesMenu__DetailsColumn" grow>
        {DetailsPanel}
      </Stack.Item>
    </Stack>
  );
}
