import { useMemo, useState } from 'react';
import { Button, Icon, NoticeBox } from 'tgui-core/components';
import { classes, type BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { CyberPointControl } from './PreferencesMenu/CharacterSetup/components/CyberInput';
import {
  CyberPanel,
  CyberSectionHeader,
} from './PreferencesMenu/CharacterSetup/components/CyberPanel';
import { SkillTree } from './PreferencesMenu/CharacterSetup/components/SkillTree';
import { attributeOrder } from './PreferencesMenu/CharacterSetup/helpers';
import type {
  CharacterSetupRuntimeSkill,
  CharacterSetupSkill,
} from './PreferencesMenu/types';

type SkillPerk = {
  index: number;
  name: string;
  description: string;
  rank_descriptions?: string[];
  max_rank?: number;
  rank: number;
  maxRank: number;
  canIncrease: BooleanLike;
  canDecrease: BooleanLike;
};

type SkillEntry = {
  id: string;
  name: string;
  title: string;
  description: string;
  kind: string;
  attributeId: string;
  attribute_id?: string;
  level: number;
  levelName: string;
  maxLevel: number;
  max_character_level?: number;
  max_perk_rank?: number;
  point_pool?: string;
  requires_sequential_perks?: BooleanLike;
  giga_perk_name?: string;
  giga_perk_desc?: string;
  spentPoints: number;
  spent_points?: number;
  convertedExperience: number;
  pendingExperience: number;
  experienceGoal?: number;
  perks: SkillPerk[];
  canIncrease: BooleanLike;
  canDecrease: BooleanLike;
  can_increase?: BooleanLike;
  can_decrease?: BooleanLike;
  editable?: BooleanLike;
  runtime_perks?: Record<string, unknown>;
  disabled_reason?: string;
  weaponDamageBonus?: number;
  weaponCooldownReduction?: number;
  weaponDefenseBreakBonus?: number;
  weapon_damage_bonus_per_level?: number;
  weapon_cooldown_reduction_per_level?: number;
  weapon_defense_break_bonus_per_level?: number;
};

type SkillchipEntry = {
  name: string;
  ref: string;
};

type ImplantMetrics = {
  chromity: number;
  chromityMax: number;
  chromityUsed: number;
  iceChromityPenalty: number;
  overheat: number;
  overheatFloor: number;
};

type InstalledImplant = {
  ref: string;
  name: string;
  description: string;
  slot: string;
  bodyPart: string;
  tier: number;
  corp: string;
  chromity: number;
  activeOverheat: number;
  damage: number;
  maxHealth: number;
  functional: BooleanLike;
  toggleable: BooleanLike;
  active: BooleanLike;
  isNeuralInterface: BooleanLike;
};

type SkillInterfaceData = {
  userName: string;
  hasNeuralInterface: BooleanLike;
  diagnosticAccess: BooleanLike;
  accessGranted: BooleanLike;
  accessCard?: string;
  memoryKeys: number;
  canWriteCryptoKey?: BooleanLike;
  cryptoKeyTarget?: string;
  levelPoints: number;
  skillPoints: number;
  professionalSkillPoints: number;
  weaponSkillPoints: number;
  unconvertedExperience: number;
  generalExperienceMax?: number;
  attributes?: Record<
    string,
    {
      value: number;
      min: number;
      max: number;
      super_threshold: number;
      editable: BooleanLike;
      disabled_reason?: string;
    }
  >;
  skills: SkillEntry[];
  skillchips: SkillchipEntry[];
  implants: InstalledImplant[];
  implantMetrics?: ImplantMetrics;
  characterPreviewView?: string;
};

const implantBodyParts = [
  {
    id: 'head',
    label: 'Голова',
    icon: 'head-side-virus',
    slotIds: [
      'neck_device',
      'os_device',
      'neural_implant',
      'brain',
      'eye_sight',
      'ears',
      'tongue',
      'eyelid_device',
    ],
  },
  {
    id: 'left_arm',
    label: 'Левая рука',
    icon: 'hand',
    slotIds: ['l_arm_device'],
  },
  {
    id: 'left_leg',
    label: 'Левая нога',
    icon: 'shoe-prints',
    slotIds: ['l_leg_device'],
  },
  {
    id: 'torso',
    label: 'Торс',
    icon: 'vest',
    slotIds: [
      'spine',
      'heart',
      'lungs',
      'stomach',
      'liver',
      'belly_device',
      'chest_device',
    ],
  },
  {
    id: 'right_arm',
    label: 'Правая рука',
    icon: 'hand',
    slotIds: ['r_arm_device'],
  },
  {
    id: 'right_leg',
    label: 'Правая нога',
    icon: 'shoe-prints',
    slotIds: ['r_leg_device'],
  },
];

const slotLabels: Record<string, { label: string; icon: string }> = {
  neural_implant: { label: 'Нейроинтерфейс', icon: 'brain' },
  os_device: { label: 'OS', icon: 'microchip' },
  brain: { label: 'Мозг', icon: 'brain' },
  eye_sight: { label: 'Глаза', icon: 'eye' },
  ears: { label: 'Уши', icon: 'ear-listen' },
  tongue: { label: 'Язык / рот', icon: 'comment' },
  eyelid_device: { label: 'Веки / HUD', icon: 'eye' },
  neck_device: { label: 'Шея', icon: 'link' },
  spine: { label: 'Позвоночник', icon: 'staff-snake' },
  heart: { label: 'Сердце', icon: 'heart-pulse' },
  lungs: { label: 'Легкие', icon: 'lungs' },
  stomach: { label: 'Желудок', icon: 'jar' },
  liver: { label: 'Печень', icon: 'flask' },
  belly_device: { label: 'Живот', icon: 'circle-dot' },
  chest_device: { label: 'Грудь', icon: 'vest' },
  l_arm_device: { label: 'Левая рука', icon: 'hand' },
  r_arm_device: { label: 'Правая рука', icon: 'hand' },
  l_leg_device: { label: 'Левая нога', icon: 'shoe-prints' },
  r_leg_device: { label: 'Правая нога', icon: 'shoe-prints' },
};

const attributeNames: Record<string, string> = {
  strength: 'Сила',
  dexterity: 'Ловкость',
  perception: 'Восприятие',
  intelligence: 'Интеллект',
  spirit: 'Дух',
  charisma: 'Харизма',
};

function skillsOfKind(skills: SkillEntry[], kind: string) {
  return (skills || []).filter((skill) => skill && skill.kind === kind);
}

function skillsForAttribute(skills: SkillEntry[], attributeId: string) {
  return (skills || []).filter(
    (skill) => skill && skill.attributeId === attributeId,
  );
}

function toImplantBodyPartSlots(implants: InstalledImplant[]) {
  const validImplants = (implants || []).filter(Boolean);
  return implantBodyParts.map((bodyPart) => {
    const bodyPartImplants = validImplants.filter(
      (implant) => implant.bodyPart === bodyPart.id,
    );
    const activeCount = bodyPartImplants.filter((implant) => implant.active).length;
    const toggleableCount = bodyPartImplants.filter(
      (implant) => implant.toggleable,
    ).length;

    return {
      id: bodyPart.id,
      icon: bodyPart.icon,
      label: bodyPart.label,
      state: `${bodyPartImplants.length}/${Math.max(bodyPart.slotIds.length, 1)}`,
      warning: bodyPartImplants.length
        ? `Активных: ${activeCount}. Переключаемых: ${toggleableCount}.`
        : 'В этой зоне нет установленных имплантов.',
    };
  });
}

function getBodyPartSlots(bodyPartId: string, implants: InstalledImplant[]) {
  const bodyPart = implantBodyParts.find((part) => part.id === bodyPartId);
  const validImplants = (implants || []).filter(Boolean);
  return (bodyPart?.slotIds || []).map((slotId) => {
    const slotImplants = validImplants.filter((implant) => implant.slot === slotId);
    const activeCount = slotImplants.filter((implant) => implant.active).length;
    const label = slotLabels[slotId]?.label || slotId;
    return {
      id: slotId,
      label,
      icon: slotLabels[slotId]?.icon || bodyPart?.icon || 'microchip',
      implants: slotImplants,
      state: slotImplants.length
        ? `${activeCount}/${slotImplants.length}`
        : slotId === 'neural_implant'
          ? '0/1'
          : '0/1',
    };
  });
}

function asSkillTreeSkill(skill: SkillEntry): CharacterSetupSkill {
  return {
    id: skill.id,
    name: skill.name,
    title: skill.title,
    description: skill.description,
    attribute_id: skill.attribute_id || skill.attributeId,
    kind: skill.kind,
    point_pool: skill.point_pool || skill.kind,
    max_character_level: skill.max_character_level || skill.maxLevel,
    max_perk_rank: skill.max_perk_rank || 0,
    requires_sequential_perks: !!skill.requires_sequential_perks,
    giga_perk_name: skill.giga_perk_name,
    giga_perk_desc: skill.giga_perk_desc,
    weapon_damage_bonus_per_level:
      skill.weapon_damage_bonus_per_level || skill.weaponDamageBonus,
    weapon_cooldown_reduction_per_level:
      skill.weapon_cooldown_reduction_per_level || skill.weaponCooldownReduction,
    weapon_defense_break_bonus_per_level:
      skill.weapon_defense_break_bonus_per_level || skill.weaponDefenseBreakBonus,
    perks: (skill.perks || []).map((perk) => ({
      index: perk.index,
      name: perk.name,
      description: perk.description,
      rank_descriptions: perk.rank_descriptions,
      max_rank: perk.max_rank || perk.maxRank,
    })),
  };
}

function buildRuntimeSkills(skills: SkillEntry[]) {
  const runtimeSkills: Record<string, CharacterSetupRuntimeSkill> = {};
  for (const skill of skills || []) {
    runtimeSkills[skill.id] = {
      level: skill.level || 0,
      spent_points: skill.spent_points ?? skill.spentPoints ?? 0,
      perks: skill.runtime_perks || {},
      can_increase: !!(skill.can_increase ?? skill.canIncrease),
      can_decrease: !!(skill.can_decrease ?? skill.canDecrease),
      editable: !!skill.editable,
      disabled_reason: skill.disabled_reason,
      converted_experience: skill.convertedExperience || 0,
      pending_experience: skill.pendingExperience || 0,
      experience_goal: skill.experienceGoal || 100,
    };
  }
  return runtimeSkills;
}

function ImplantCard(props: {
  implant: InstalledImplant;
  canToggle: boolean;
  onToggle: (implant: InstalledImplant) => void;
}) {
  const { implant } = props;
  return (
    <div
      className={classes([
        'SkillInterface__implantCard',
        implant.active && 'active',
        implant.isNeuralInterface && 'neural',
      ])}
    >
      <div className="SkillInterface__implantInfo">
        <b>{implant.name}</b>
        <span>{implant.description}</span>
        <small>
          Слот: {slotLabels[implant.slot]?.label || implant.slot} / T
          {implant.tier || 1} / {implant.corp || 'independent'}
        </small>
        <small>
          Хром: {implant.chromity || 0}
          {!!implant.activeOverheat && `, активный перегрев: ${implant.activeOverheat}`}
          {` / Урон: ${implant.damage || 0}/${implant.maxHealth || 0}`}
        </small>
      </div>
      <div className="SkillInterface__implantActions">
        {implant.isNeuralInterface ? (
          <span className="SkillInterface__implantBadge">Доступ</span>
        ) : (
          <Button
            icon={implant.active ? 'toggle-on' : 'toggle-off'}
            color={implant.active ? 'good' : undefined}
            disabled={!props.canToggle || !implant.toggleable || !implant.functional}
            onClick={() => props.onToggle(implant)}
          >
            {implant.toggleable
              ? implant.active
                ? 'Выключить'
                : 'Включить'
              : 'Пассивный'}
          </Button>
        )}
      </div>
    </div>
  );
}

export const CyberpunkSkillInterface = () => {
  const { act, data } = useBackend<SkillInterfaceData>();
  const { accessGranted, diagnosticAccess, hasNeuralInterface } = data;
  const implants = Array.isArray(data.implants)
    ? data.implants.filter(Boolean)
    : [];
  const skillchips = Array.isArray(data.skillchips)
    ? data.skillchips.filter(Boolean)
    : [];
  const skills = Array.isArray(data.skills) ? data.skills.filter(Boolean) : [];
  const runtimeAttributes = data.attributes || {};
  const [selectedAttribute, setSelectedAttribute] = useState('strength');
  const physicalSkills = useMemo(() => skillsOfKind(skills, 'physical'), [skills]);
  const professionalSkills = useMemo(
    () => skillsOfKind(skills, 'professional'),
    [skills],
  );
  const weaponSkills = useMemo(() => skillsOfKind(skills, 'weapon'), [skills]);
  const skillTreePhysicalSkills = useMemo(
    () => physicalSkills.map(asSkillTreeSkill),
    [physicalSkills],
  );
  const skillTreeProfessionalSkills = useMemo(
    () => professionalSkills.map(asSkillTreeSkill),
    [professionalSkills],
  );
  const skillTreeWeaponSkills = useMemo(
    () => weaponSkills.map(asSkillTreeSkill),
    [weaponSkills],
  );
  const runtimeSkills = useMemo(() => buildRuntimeSkills(skills), [skills]);
  const attributeSkills = useMemo(
    () => skillsForAttribute(physicalSkills, selectedAttribute),
    [physicalSkills, selectedAttribute],
  );
  const canToggleImplants = !!hasNeuralInterface;
  const metrics = data.implantMetrics;
  const generalExperienceMax = data.generalExperienceMax || 100;
  const generalExperienceProgress = Math.min(
    100,
    Math.round(
      ((data.unconvertedExperience || 0) / Math.max(generalExperienceMax, 1)) *
        100,
    ),
  );

  const adjustPerk = (skillId: string, perkIndex: number, delta: number) =>
    act('adjust_perk', {
      skill: skillId,
      perkIndex,
      delta,
    });
  const adjustSkillLevel = (skillId: string, delta: number) =>
    act('adjust_skill_level', {
      skill: skillId,
      delta,
    });

  return (
    <Window title="Skill Interface" width={1240} height={840}>
      <Window.Content className="CharacterSetup SkillInterface" scrollable>
        <header className="CharacterSetup__topbar">
          <div className="CharacterSetup__brand">
            <Icon name="eye" />
            <div>
              <b>ИНТЕРФЕЙС НАВЫКОВ</b>
              <span>SPACE STATION 13</span>
            </div>
          </div>
          <div className="SkillInterface__topMetrics">
            <span>Пользователь: {data.userName}</span>
            <span>
              Доступ:{' '}
              {diagnosticAccess
                ? 'диагностический анализ'
                : hasNeuralInterface
                  ? 'нейроинтерфейс'
                  : 'нет'}
            </span>
            <span>Опыт: {Math.round(data.unconvertedExperience || 0)}</span>
            <span>Ключи памяти: {data.memoryKeys || 0}</span>
          </div>
          <div className="CharacterSetup__topActions">
            <Button
              icon="microchip"
              disabled={!hasNeuralInterface}
              onClick={() => act('install_skillchip')}
            >
              Чип из руки
            </Button>
            <Button
              icon="eject"
              disabled={!hasNeuralInterface || !skillchips.length}
              onClick={() => act('remove_skillchip')}
            >
              Быстро извлечь
            </Button>
            <Button
              icon="id-card"
              disabled={!hasNeuralInterface || !data.accessCard}
              onClick={() => act('sync_card')}
            >
              Синхр. ID
            </Button>
          </div>
          <div className="SkillInterface__generalXp">
            <div className="SkillInterface__generalXpLabel">
              <b>Опыт характеристики</b>
              <span>
                {Math.round(data.unconvertedExperience || 0)}/
                {generalExperienceMax}
              </span>
            </div>
            <div className="SkillInterface__generalXpTrack">
              <span style={{ width: `${generalExperienceProgress}%` }} />
            </div>
          </div>
        </header>

        <main className="CharacterSetup__content">
          {!accessGranted && (
            <NoticeBox danger>
              Нейроинтерфейс не найден. Используйте машину диагностического анализа.
            </NoticeBox>
          )}
          <div className="CharacterSetup__layout SkillInterface__layout">
            <CyberPanel title="A. Атрибуты и развитие" scrollable>
              <CyberSectionHeader>Базовые характеристики</CyberSectionHeader>
              <div className="CharacterSetup__spent">
                <span>Очки характеристик: {data.levelPoints || 0}</span>
              </div>
              {attributeOrder.map((attributeId) => {
                const runtimeAttribute = runtimeAttributes[attributeId];
                const attributeValue = runtimeAttribute?.value || 5;
                const spentPhysicalPoints = skillsForAttribute(
                  physicalSkills,
                  attributeId,
                ).reduce(
                  (sum, skill) =>
                    sum + (skill.spent_points ?? skill.spentPoints ?? 0),
                  0,
                );
                return (
                  <div
                    key={attributeId}
                    className={
                      selectedAttribute === attributeId
                        ? 'CharacterSetup__attribute active'
                        : 'CharacterSetup__attribute'
                    }
                    onClick={() => setSelectedAttribute(attributeId)}
                  >
                    <CyberPointControl
                      disabled={!runtimeAttribute?.editable}
                      label={attributeNames[attributeId] || attributeId}
                      max={runtimeAttribute?.max}
                      min={runtimeAttribute?.min}
                      minusDisabled={spentPhysicalPoints >= attributeValue}
                      plusDisabled
                      reason={runtimeAttribute?.disabled_reason}
                      value={attributeValue}
                      onMinus={() => undefined}
                      onPlus={() => undefined}
                    />
                  </div>
                );
              })}
              <CyberSectionHeader>
                Развитие: {attributeNames[selectedAttribute] || selectedAttribute}
              </CyberSectionHeader>
              <div className="CharacterSetup__spent">
                <span>
                  Вложено:{' '}
                  {attributeSkills.reduce(
                    (sum, skill) => sum + (skill.spent_points ?? skill.spentPoints ?? 0),
                    0,
                  )}
                </span>
                <span>Лимит: {runtimeAttributes[selectedAttribute]?.value || 0}</span>
              </div>
              <SkillTree
                attributeId={selectedAttribute}
                runtimeSkills={runtimeSkills}
                skills={skillTreePhysicalSkills}
                onAdjustPerk={adjustPerk}
              />
            </CyberPanel>

            <CyberPanel
              className="CharacterSetup__centerPanel CharacterSetup__biometricsPanel"
              title="C. Аугментации и импланты"
            >
              <div className="CharacterSetup__metrics">
                <span>
                  Хромированность: {metrics?.chromity ?? 0}/
                  {metrics?.chromityMax ?? 0}
                  {!!metrics?.chromityUsed && ` (-${metrics.chromityUsed})`}
                  {!!metrics?.iceChromityPenalty &&
                    `, лед -${metrics.iceChromityPenalty}`}
                </span>
                <span>
                  Перегрев: {metrics?.overheat ?? 0}
                  {!!metrics?.overheatFloor && ` / пол ${metrics.overheatFloor}`}
                </span>
              </div>
              <CyberSectionHeader>Установленные импланты</CyberSectionHeader>
              <div className="CharacterSetup__headerActions">
                <Button
                  icon="key"
                  disabled={!data.canWriteCryptoKey}
                  tooltip={
                    data.cryptoKeyTarget
                      ? `Записать ключи на ${data.cryptoKeyTarget}`
                      : 'Нужна нейропамять и карта/диск/чип в руке'
                  }
                  onClick={() => act('write_crypto_key')}
                >
                  Записать ключи
                </Button>
              </div>
              <div className="SkillInterface__implantList">
                {implants.map((implant) => (
                  <ImplantCard
                    key={implant.ref}
                    implant={implant}
                    canToggle={canToggleImplants}
                    onToggle={(target) =>
                      act('toggle_cyberimp', { ref: target.ref })
                    }
                  />
                ))}
                {!implants.length && (
                  <div className="CharacterSetup__localNote">
                    Установленных имплантов не найдено.
                  </div>
                )}
              </div>
            </CyberPanel>

            <CyberPanel title="B. Навыки и профессиональный рост" scrollable>
              <CyberSectionHeader>Профессиональные навыки</CyberSectionHeader>
              <div className="SkillTree__pool">
                <span>Очки профессий: {data.professionalSkillPoints || 0}</span>
              </div>
              <SkillTree
                compact
                runtimeSkills={runtimeSkills}
                skills={skillTreeProfessionalSkills}
                onAdjustPerk={adjustPerk}
              />
              <CyberSectionHeader>Боевые / оружейные навыки</CyberSectionHeader>
              <div className="SkillTree__pool">
                <span>Очки боя: {data.weaponSkillPoints || 0}</span>
              </div>
              <SkillTree
                compact
                runtimeSkills={runtimeSkills}
                skills={skillTreeWeaponSkills}
                onAdjustPerk={adjustPerk}
                onAdjustSkillLevel={adjustSkillLevel}
              />
            </CyberPanel>
          </div>
        </main>
      </Window.Content>
    </Window>
  );
};
