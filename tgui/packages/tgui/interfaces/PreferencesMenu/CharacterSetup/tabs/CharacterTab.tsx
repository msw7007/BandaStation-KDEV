import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Button, Dropdown } from 'tgui-core/components';

import type {
  BodyModification,
  CharacterSetupImplantSlot,
  CharacterSetupSkill,
  PreferencesMenuData,
} from '../../types';
import { useServerPrefs } from '../../useServerPrefs';
import {
  CharacterPaperdollHub,
  type PaperdollSlot,
} from '../components/CharacterPaperdollHub';
import { CyberPointControl } from '../components/CyberInput';
import { CyberPanel, CyberSectionHeader } from '../components/CyberPanel';
import { SkillTree } from '../components/SkillTree';
import { attributeOrder } from '../helpers';

const implantBodyParts = [
  {
    id: 'head',
    label: 'Голова',
    icon: 'head-side-virus',
    slotIds: [
      'neck',
      'skull',
      'brain',
      'eyes',
      'ears',
      'tongue',
      'jaw',
      'eyelids',
      'neural_implant',
    ],
  },
  {
    id: 'left_arm',
    label: 'Левая рука',
    icon: 'hand',
    slotIds: ['left_arm_1', 'left_arm_2'],
  },
  {
    id: 'left_leg',
    label: 'Левая нога',
    icon: 'shoe-prints',
    slotIds: ['left_leg'],
  },
  {
    id: 'torso',
    label: 'Торс',
    icon: 'vest',
    slotIds: [
      'spine_1',
      'spine_2',
      'heart',
      'lungs',
      'stomach',
      'liver',
      'belly',
      'chest',
    ],
  },
  {
    id: 'right_arm',
    label: 'Правая рука',
    icon: 'hand',
    slotIds: ['right_arm_1', 'right_arm_2'],
  },
  {
    id: 'right_leg',
    label: 'Правая нога',
    icon: 'shoe-prints',
    slotIds: ['right_leg'],
  },
];

function toImplantBodyPartSlots(slots: CharacterSetupImplantSlot[] = []): PaperdollSlot[] {
  const slotsById = new Map(slots.map((slot) => [slot.id, slot]));

  return implantBodyParts.map((bodyPart) => {
    const bodyPartSlots = bodyPart.slotIds
      .map((slotId) => slotsById.get(slotId))
      .filter((slot): slot is CharacterSetupImplantSlot => !!slot);
    const occupiedSlots = bodyPartSlots.filter(
      (slot) => slot.default_state !== 'empty',
    ).length;
    const slotNames = bodyPartSlots.map((slot) => slot.name).join(', ');

    return {
      id: bodyPart.id,
      icon: bodyPart.icon,
      label: bodyPart.label,
      state: `${occupiedSlots}/${bodyPartSlots.length}`,
      disabled: true,
      warning: slotNames
        ? `Внутренние слоты: ${slotNames}. Операции установки/извлечения здесь не запускаются.`
        : 'Нет доступных внутренних слотов.',
    };
  });
}

function skillsForAttribute(skills: CharacterSetupSkill[], attributeId: string) {
  return skills.filter((skill) => skill.attribute_id === attributeId);
}

function groupBodyModifications(modifications: BodyModification[] = []) {
  return modifications.reduce<Record<string, BodyModification[]>>((groups, modification) => {
    const groupName = modification.category || 'Прочее';
    groups[groupName] ||= [];
    groups[groupName].push(modification);
    return groups;
  }, {});
}

function BodyModificationList() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs();
  const groupedModifications = groupBodyModifications(serverData?.body_modifications || []);
  const applied = new Set(data.applied_body_modifications || []);
  const incompatible = new Set(data.incompatible_body_modifications || []);
  const manufacturers = data.manufacturers || {};
  const selectedManufacturer = data.selected_manufacturer || {};

  if (!serverData?.body_modifications?.length) {
    return (
      <div className="CharacterSetup__localNote">
        В текущих prefs нет доступных модификаций тела.
      </div>
    );
  }

  return (
    <div className="CharacterSetup__bodyMods">
      {Object.entries(groupedModifications).map(([category, modifications]) => (
        <div className="CharacterSetup__bodyModGroup" key={category}>
          <b>{category}</b>
          {modifications.map((modification) => {
            const isApplied = applied.has(modification.key);
            const isBlocked = incompatible.has(modification.key) && !isApplied;
            const manufacturerOptions = manufacturers[modification.key] || [];

            return (
              <div
                className={
                  isApplied
                    ? 'CharacterSetup__bodyModRow selected'
                    : 'CharacterSetup__bodyModRow'
                }
                key={modification.key}
              >
                <div>
                  <strong>{modification.name}</strong>
                  <span>{modification.description}</span>
                  {!!modification.cost && <small>Стоимость: {modification.cost}</small>}
                  {isBlocked && <em>Несовместимо с выбранными модификациями</em>}
                </div>
                <div className="CharacterSetup__bodyModActions">
                  {isApplied && !!manufacturerOptions.length && (
                    <Dropdown
                      buttons
                      selected={selectedManufacturer[modification.key]}
                      displayText={
                        selectedManufacturer[modification.key] ||
                        manufacturerOptions[0]
                      }
                      options={manufacturerOptions}
                      width="10rem"
                      onSelected={(manufacturer) =>
                        act('set_body_modification_manufacturer', {
                          body_modification_key: modification.key,
                          manufacturer,
                        })
                      }
                    />
                  )}
                  <Button
                    icon={isApplied ? 'minus' : 'plus'}
                    color={isApplied ? 'red' : 'green'}
                    disabled={isBlocked}
                    onClick={() =>
                      act(
                        isApplied
                          ? 'remove_body_modification'
                          : 'apply_body_modification',
                        {
                          body_modification_key: modification.key,
                        },
                      )
                    }
                  >
                    {isApplied ? 'Снять' : 'Выбрать'}
                  </Button>
                </div>
              </div>
            );
          })}
        </div>
      ))}
    </div>
  );
}

export function CharacterTab() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs();
  const setup = serverData?.character_setup;
  const runtime = data.character_setup;
  const [selectedAttribute, setSelectedAttribute] = useState('strength');

  const attributeDefs = setup?.attributes || {};
  const runtimeAttributes = runtime?.attributes || {};
  const runtimeSkills = runtime?.skills || {};
  const metrics = runtime?.implant_metrics;
  const levelPoints = runtime?.level_points || 0;
  const professionalSkillPoints = runtime?.professional_skill_points || 0;
  const weaponSkillPoints = runtime?.weapon_skill_points || 0;

  const adjustAttribute = (attributeId: string, delta: number) =>
    act('adjust_character_attribute', {
      attribute_id: attributeId,
      delta,
    });

  const adjustPerk = (skillId: string, perkIndex: number, delta: number) =>
    act('adjust_character_perk', {
      skill: skillId,
      perk_index: perkIndex,
      delta,
    });

  const adjustSkillLevel = (skillId: string, delta: number) =>
    act('adjust_character_skill_level', {
      skill: skillId,
      delta,
    });

  return (
    <div className="CharacterSetup__layout">
      <CyberPanel title="A. Атрибуты и развитие" scrollable>
        <CyberSectionHeader>Базовые характеристики</CyberSectionHeader>
        <div className="CharacterSetup__spent">
          <span>Очки характеристик: {levelPoints}</span>
        </div>
        {attributeOrder.map((attributeId) => {
          const attribute = attributeDefs[attributeId];
          const runtimeAttribute = runtimeAttributes[attributeId];
          const attributeValue = runtimeAttribute?.value || 5;
          const spentPhysicalPoints = skillsForAttribute(
            setup?.physical_skills || [],
            attributeId,
          ).reduce(
            (sum, skill) => sum + (runtimeSkills[skill.id]?.spent_points || 0),
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
                label={attribute?.name || attributeId}
                max={runtimeAttribute?.max}
                min={runtimeAttribute?.min}
                minusDisabled={spentPhysicalPoints >= attributeValue}
                plusDisabled={levelPoints <= 0}
                reason={runtimeAttribute?.disabled_reason}
                value={attributeValue}
                onMinus={() => adjustAttribute(attributeId, -1)}
                onPlus={() => adjustAttribute(attributeId, 1)}
              />
            </div>
          );
        })}

        <CyberSectionHeader>
          Развитие: {attributeDefs[selectedAttribute]?.name || selectedAttribute}
        </CyberSectionHeader>
        <div className="CharacterSetup__spent">
          <span>
            Вложено:{' '}
            {skillsForAttribute(setup?.physical_skills || [], selectedAttribute).reduce(
              (sum, skill) => sum + (runtimeSkills[skill.id]?.spent_points || 0),
              0,
            )}
          </span>
          <span>Лимит: {runtimeAttributes[selectedAttribute]?.value || 5}</span>
        </div>
        <SkillTree
          attributeId={selectedAttribute}
          runtimeSkills={runtimeSkills}
          skills={setup?.physical_skills || []}
          onAdjustPerk={adjustPerk}
        />
      </CyberPanel>

      <CyberPanel
        className="CharacterSetup__centerPanel"
        title="C. Аугментации и импланты"
        scrollable
      >
        <div className="CharacterSetup__metrics">
          <span>Хромированность: {metrics?.chromity ?? 50}/{metrics?.chromity_max ?? 50}</span>
          <span>Перегрев: {metrics?.overheat ?? 0}</span>
        </div>
        <CharacterPaperdollHub
          previewId={data.character_preview_view}
          slots={toImplantBodyPartSlots(setup?.implant_slots)}
        />
        <div className="CharacterSetup__localNote">
          Слоты отображаются как build preview. Операции установки/извлечения
          здесь не запускаются.
        </div>
        <CyberSectionHeader>Протезы и модификации тела</CyberSectionHeader>
        <BodyModificationList />
      </CyberPanel>

      <CyberPanel title="B. Навыки и профессиональный рост" scrollable>
        <CyberSectionHeader>Профессиональные навыки</CyberSectionHeader>
        <div className="SkillTree__pool">
          <span>Очки профессий: {professionalSkillPoints}</span>
        </div>
        <SkillTree
          compact
          runtimeSkills={runtimeSkills}
          skills={setup?.professional_skills || []}
          onAdjustPerk={adjustPerk}
        />
        <CyberSectionHeader>Боевые / оружейные навыки</CyberSectionHeader>
        <div className="SkillTree__pool">
          <span>Очки боя: {weaponSkillPoints}</span>
        </div>
        <SkillTree
          compact
          runtimeSkills={runtimeSkills}
          skills={setup?.weapon_skills || []}
          onAdjustSkillLevel={adjustSkillLevel}
        />
      </CyberPanel>
    </div>
  );
}
