import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Button, DmIcon, Dropdown, Icon } from 'tgui-core/components';

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
import { SlotButton } from '../components/SlotButton';
import { attributeOrder } from '../helpers';

const implantBodyParts = [
  {
    id: 'head',
    label: 'Голова',
    icon: 'head-side-virus',
    slotIds: [
      'neck_device',
      'skull_device',
      'brain',
      'brain_cns',
      'eye_sight',
      'ears',
      'tongue',
      'jaw_device',
      'eyelid_device',
    ],
  },
  {
    id: 'left_arm',
    label: 'Левая рука',
    icon: 'hand',
    slotIds: ['l_arm_device', 'l_arm_muscle'],
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
      'spine_secondary',
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
    slotIds: ['r_arm_device', 'r_arm_muscle'],
  },
  {
    id: 'right_leg',
    label: 'Правая нога',
    icon: 'shoe-prints',
    slotIds: ['r_leg_device'],
  },
];

function toImplantBodyPartSlots(
  slots: CharacterSetupImplantSlot[] = [],
): PaperdollSlot[] {
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
      warning: slotNames
        ? `Внутренние слоты: ${slotNames}. Операции установки/извлечения здесь не запускаются.`
        : 'Нет доступных внутренних слотов.',
    };
  });
}

function skillsForAttribute(skills: CharacterSetupSkill[], attributeId: string) {
  return skills.filter((skill) => skill.attribute_id === attributeId);
}

const bodyModificationKindLabels: Record<string, string> = {
  amputation: 'Ампутации',
  feature: 'Особенности',
  implant: 'Импланты',
  organ: 'Органы',
  prosthesis: 'Протезы',
};

type ModificationSlotOption = {
  id: string;
  label: string;
  icon: string;
  kind: 'slot' | 'limb' | 'placeholder';
  slotId?: string;
  disabled?: boolean;
  state?: string;
};

function getBodyPartModificationSlots(
  bodyPartId: string,
  slots: CharacterSetupImplantSlot[] = [],
): ModificationSlotOption[] {
  const bodyPart = implantBodyParts.find((part) => part.id === bodyPartId);
  const slotsById = new Map(slots.map((slot) => [slot.id, slot]));
  const options: ModificationSlotOption[] = [];

  if (['left_arm', 'right_arm', 'left_leg', 'right_leg'].includes(bodyPartId)) {
    options.push({
      id: `${bodyPartId}:limb`,
      label: 'Роботизация',
      icon: bodyPartId.includes('arm') ? 'hand' : 'shoe-prints',
      kind: 'limb',
      state: 'body',
    });
  }

  if (['head', 'torso'].includes(bodyPartId)) {
    options.push({
      id: `${bodyPartId}:robotization`,
      label:
        bodyPartId === 'head'
          ? 'Роботизация головы'
          : 'Роботизация торса',
      icon: bodyPartId === 'head' ? 'head-side-virus' : 'vest',
      kind: 'placeholder',
      disabled: true,
      state: 'TODO',
    });
  }

  for (const slotId of bodyPart?.slotIds || []) {
    const slot = slotsById.get(slotId);
    options.push({
      id: `slot:${slotId}`,
      label: slot?.name || slotId,
      icon: slot?.icon || bodyPart?.icon || 'microchip',
      kind: 'slot',
      slotId,
      state: slot?.default_state === 'empty' ? '0/1' : '1/1',
    });
  }

  return options;
}

function groupBodyModifications(modifications: BodyModification[] = []) {
  return modifications.reduce<Record<string, BodyModification[]>>(
    (groups, modification) => {
      const kindName =
        bodyModificationKindLabels[modification.kind || ''] ||
        modification.category ||
        'Прочее';
      const groupName = modification.grade
        ? `${kindName}: ${modification.grade}`
        : kindName;
      groups[groupName] ||= [];
      groups[groupName].push(modification);
      return groups;
    },
    {},
  );
}

type BodyModificationListProps = {
  selectedBodyPart?: string | null;
  selectedSlot?: ModificationSlotOption | null;
  slots?: CharacterSetupImplantSlot[];
};

function BodyModificationList(props: BodyModificationListProps) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs();
  const { selectedBodyPart, selectedSlot, slots = [] } = props;
  const [search, setSearch] = useState('');
  const slotNames = new Map(slots.map((slot) => [slot.id, slot.name]));
  const applied = new Set(data.applied_body_modifications || []);
  const incompatible = new Set(data.incompatible_body_modifications || []);
  const manufacturers = data.manufacturers || {};
  const selectedManufacturer = data.selected_manufacturer || {};
  const searchLower = search.trim().toLowerCase();

  const zoneModifications = (serverData?.body_modifications || [])
    .filter((modification) => {
      if (!selectedSlot || !selectedBodyPart || selectedSlot.disabled) {
        return false;
      }

      if (selectedSlot.kind === 'limb') {
        return (
          modification.body_part === selectedBodyPart &&
          ['amputation', 'prosthesis'].includes(modification.kind || '')
        );
      }

      return modification.slot_id === selectedSlot.slotId;
    })
    .filter((modification) => {
      if (!searchLower) {
        return true;
      }
      return (
        modification.name.toLowerCase().includes(searchLower) ||
        modification.description.toLowerCase().includes(searchLower)
      );
    });
  const groupedModifications = groupBodyModifications(zoneModifications);

  const filterControls = (
    <div className="CharacterSetup__bodyModFilters">
      <input
        placeholder="Поиск..."
        value={search}
        onChange={(event) => setSearch(event.currentTarget.value)}
      />
    </div>
  );

  if (!selectedSlot) {
    return (
      <div className="CharacterSetup__localNote">
        Выберите слот или роботизацию зоны, чтобы открыть список модификаций.
      </div>
    );
  }

  if (selectedSlot.disabled) {
    return (
      <div className="CharacterSetup__localNote">
        Эта категория пока заготовлена под общую систему модификаций.
      </div>
    );
  }

  if (!zoneModifications.length) {
    return (
      <div className="CharacterSetup__bodyMods">
        {filterControls}
        <div className="CharacterSetup__localNote">
          Для выбранного слота нет доступных модификаций.
        </div>
      </div>
    );
  }

  return (
    <div className="CharacterSetup__bodyMods">
      {filterControls}
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
                <div className="CharacterSetup__bodyModInfo">
                  <div className="CharacterSetup__bodyModIcon">
                    {modification.icon && modification.icon_state ? (
                      <DmIcon
                        height="32px"
                        icon={modification.icon}
                        icon_state={modification.icon_state}
                        width="32px"
                      />
                    ) : (
                      <Icon
                        name={
                          modification.kind === 'amputation'
                            ? 'scissors'
                            : modification.kind === 'prosthesis'
                              ? 'hand'
                              : modification.kind === 'organ'
                                ? 'heart-pulse'
                                : 'microchip'
                        }
                      />
                    )}
                  </div>
                  <div className="CharacterSetup__bodyModText">
                    <strong>{modification.name}</strong>
                    <span>{modification.description}</span>
                    {!!modification.grade && (
                      <small>
                        Градация: {modification.grade}
                        {!!modification.tier && ` / T${modification.tier}`}
                      </small>
                    )}
                    {!!modification.locked_reason && (
                      <small>{modification.locked_reason}</small>
                    )}
                    {!!modification.cost && (
                      <small>Стоимость: {modification.cost}</small>
                    )}
                    {!!modification.chromity_cost && (
                      <small>Хром: {modification.chromity_cost}</small>
                    )}
                    {!!modification.slot_id && (
                      <small>
                        Слот:{' '}
                        {slotNames.get(modification.slot_id) ||
                          modification.slot_id}
                      </small>
                    )}
                    {isBlocked && (
                      <em>Несовместимо с выбранными модификациями</em>
                    )}
                  </div>
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
  const [selectedBodyPart, setSelectedBodyPart] = useState<string | null>(null);
  const [selectedModificationSlotId, setSelectedModificationSlotId] =
    useState<string | null>(null);

  const attributeDefs = setup?.attributes || {};
  const runtimeAttributes = runtime?.attributes || {};
  const runtimeSkills = runtime?.skills || {};
  const metrics = runtime?.implant_metrics;
  const levelPoints = runtime?.level_points || 0;
  const professionalSkillPoints = runtime?.professional_skill_points || 0;
  const weaponSkillPoints = runtime?.weapon_skill_points || 0;
  const selectedImplantBodyPart = implantBodyParts.find(
    (bodyPart) => bodyPart.id === selectedBodyPart,
  );
  const modificationSlots = selectedBodyPart
    ? getBodyPartModificationSlots(selectedBodyPart, setup?.implant_slots)
    : [];
  const selectedModificationSlot =
    modificationSlots.find((slot) => slot.id === selectedModificationSlotId) ||
    null;

  const selectBodyPart = (bodyPartId: string) => {
    setSelectedBodyPart(bodyPartId);
    setSelectedModificationSlotId(null);
  };

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
            {skillsForAttribute(
              setup?.physical_skills || [],
              selectedAttribute,
            ).reduce(
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
        className="CharacterSetup__centerPanel CharacterSetup__biometricsPanel"
        title="C. Аугментации и импланты"
      >
        <div className="CharacterSetup__implantFixed">
          <div className="CharacterSetup__metrics">
            <span>
              Хромированность: {metrics?.chromity ?? 50}/
              {metrics?.chromity_max ?? 50}
              {!!metrics?.chromity_used && ` (-${metrics.chromity_used})`}
              {!!metrics?.ice_chromity_penalty &&
                `, лед -${metrics.ice_chromity_penalty}`}
            </span>
            <span>Перегрев: {metrics?.overheat ?? 0}</span>
          </div>
          <CharacterPaperdollHub
            previewId={data.character_preview_view}
            selectedSlot={selectedBodyPart || undefined}
            slots={toImplantBodyPartSlots(setup?.implant_slots)}
            onSelectSlot={selectBodyPart}
          />
          <div className="CharacterSetup__localNote">
            Слоты отображаются как build preview. Операции установки/извлечения
            здесь не запускаются.
          </div>
        </div>
        <div className="CharacterSetup__implantScroll">
          <CyberSectionHeader>
            {selectedImplantBodyPart?.label || 'Выберите зону'}
          </CyberSectionHeader>
          {!selectedBodyPart ? (
            <div className="CharacterSetup__localNote">
              Нажмите на голову, торс, руку или ногу вокруг куклы.
            </div>
          ) : (
            <>
              <div className="CharacterSetup__implantSlotGrid">
                {modificationSlots.map((slot) => (
                  <SlotButton
                    key={slot.id}
                    disabled={slot.disabled}
                    icon={slot.icon}
                    label={slot.label}
                    selected={selectedModificationSlotId === slot.id}
                    state={slot.state}
                    warning={
                      slot.disabled
                        ? 'Заготовка под общую роботизацию зоны.'
                        : undefined
                    }
                    onClick={() => setSelectedModificationSlotId(slot.id)}
                  />
                ))}
              </div>
              <BodyModificationList
                selectedBodyPart={selectedBodyPart}
                selectedSlot={selectedModificationSlot}
                slots={setup?.implant_slots}
              />
            </>
          )}
        </div>
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
