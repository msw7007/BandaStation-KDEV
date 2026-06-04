import { useEffect, useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { CharacterPreview } from 'tgui/interfaces/common/CharacterPreview';
import { DmIcon, Icon, ImageButton } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import type {
  LoadoutItem,
  LoadoutManagerData,
  typePath,
} from '../../CharacterPreferences/loadout/base';
import { LoadoutModifyDimmer } from '../../CharacterPreferences/loadout/ModifyPanel';
import type {
  CyberpunkPersistentAreaRecord,
  CyberpunkVisualDesign,
  ServerData,
} from '../../types';
import { useServerPrefs } from '../../useServerPrefs';
import { CyberButton, CyberColorButton } from '../components/CyberInput';
import { CyberPanel, CyberSectionHeader } from '../components/CyberPanel';
import { ItemCard } from '../components/ItemCard';
import { LoadoutSlotGrid } from '../components/LoadoutSlotGrid';
import {
  flattenLoadoutCatalog,
  getDisplayName,
  getPreferenceValue,
  setPreference,
} from '../helpers';

const allCategory = 'Все';
const underwearPreferenceBySlot: Record<string, string> = {
  undershirt: 'undershirt',
  underwear: 'underwear',
  tights: 'socks',
};

const underwearSlotLabels: Record<string, string> = {
  undershirt: 'Верхнее белье',
  underwear: 'Нижнее белье',
  tights: 'Носки',
};

const slotFlagBySlot: Record<string, number> = {
  suit: 1 << 0,
  uniform: 1 << 1,
  gloves: 1 << 2,
  glasses: 1 << 3,
  ears: 1 << 4,
  mask: 1 << 5,
  head: 1 << 6,
  shoes: 1 << 7,
  belt: 1 << 9,
  neck: 1 << 12,
  hand_l: 1 << 13,
  hand_r: 1 << 13,
  pocket_l: 1 << 15,
  pocket_r: 1 << 16,
  undershirt: 1 << 19,
  underwear: 1 << 20,
  tights: 1 << 21,
  shoulder_l: 1 << 22,
  shoulder_r: 1 << 23,
  finger: 1 << 24,
  bracers: 1 << 25,
  pants: 1 << 26,
  chest: 1 << 27,
};

const groupedSlotFlags: Record<string, number> = {
  hands: slotFlagBySlot.hand_l,
  pockets: slotFlagBySlot.pocket_l | slotFlagBySlot.pocket_r,
  shoulders: slotFlagBySlot.shoulder_l | slotFlagBySlot.shoulder_r,
  body:
    slotFlagBySlot.uniform |
    slotFlagBySlot.suit |
    slotFlagBySlot.pants |
    slotFlagBySlot.chest |
    slotFlagBySlot.undershirt |
    slotFlagBySlot.underwear |
    slotFlagBySlot.tights,
};

type EquipmentMode = 'loadout' | 'equipment';

type CatalogItem = LoadoutItem & { category: string };

type PersistentCardProps = {
  icon?: string;
  meta?: string;
  onClick?: () => void;
  onContextMenu?: () => void;
  selected?: boolean;
  subtitle?: string;
  title: string;
};

type PreferenceIconCatalog = {
  choices?: string[];
  display_names?: Record<string, string>;
  icons?: Record<string, string>;
};

function findLoadoutItem(items: CatalogItem[], path: typePath) {
  return items.find((item) => item.path === path);
}

function getLoadoutAmount(
  loadoutList: LoadoutManagerData['character_preferences']['misc']['loadout_list'],
  path: typePath,
) {
  const itemData = loadoutList[path];
  if (!itemData || Array.isArray(itemData)) {
    return 1;
  }
  const amount = Number(itemData.amount);
  return Number.isFinite(amount) && amount > 0 ? amount : 1;
}

function getLoadoutEquipSlot(
  loadoutList: LoadoutManagerData['character_preferences']['misc']['loadout_list'],
  path: typePath,
) {
  const itemData = loadoutList[path];
  if (!itemData || Array.isArray(itemData)) {
    return undefined;
  }
  const slot = itemData.equip_slot;
  return typeof slot === 'string' && slot.length ? slot : undefined;
}

function formatAreaRecord(record: CyberpunkPersistentAreaRecord) {
  return record.area_name || record.area || record.area_type || 'Persistent area';
}

function PersistentCard(props: PersistentCardProps) {
  const { icon, meta, onClick, onContextMenu, selected, subtitle, title } = props;

  return (
    <button
      className={classes(['PersistentInventoryCard', selected && 'selected'])}
      type="button"
      onClick={onClick}
      onMouseDown={(event) => {
        if (event.button !== 2 || !onContextMenu) {
          return;
        }
        event.preventDefault();
        onContextMenu();
      }}
      onContextMenu={(event) => {
        if (!onContextMenu) {
          return;
        }
        event.preventDefault();
        onContextMenu();
      }}
    >
      <span className="PersistentInventoryCard__icon">
        <Icon name={icon || 'database'} />
      </span>
      <span className="PersistentInventoryCard__body">
        <b>{title}</b>
        {!!subtitle && <small>{subtitle}</small>}
      </span>
      {!!meta && <em>{meta}</em>}
    </button>
  );
}

function getWardrobeDesignId(design: CyberpunkVisualDesign, index: number) {
  return design.id || `${design.type_path || design.base || design.kind || 'wardrobe'}-${index}`;
}

function wardrobeDesignMatchesSlot(
  design: CyberpunkVisualDesign,
  slot: string | null,
) {
  if (!slot) {
    return true;
  }
  const text = `${design.kind || ''} ${design.base || ''} ${design.type_path || ''} ${design.name || ''}`.toLowerCase();
  switch (slot) {
    case 'uniform':
      return /under|uniform|jumpsuit|костюм|униформ/.test(text);
    case 'suit':
      return /suit|outer|coat|jacket|верх/.test(text);
    case 'pants':
      return /pants|trouser|штаны|брюк/.test(text);
    case 'shoes':
      return /shoe|boot|сапог|ботин/.test(text);
    case 'gloves':
      return /glove|перчат/.test(text);
    case 'head':
      return /head|hat|helmet|cap|голов|шлем/.test(text);
    case 'mask':
      return /mask|маск/.test(text);
    case 'glasses':
      return /glasses|очки/.test(text);
    case 'neck':
      return /neck|tie|scarf|collar|шея|галстук|шарф/.test(text);
    case 'ears':
      return /ear|headset|уши|науш/.test(text);
    case 'underwear':
      return /underwear|нижн/.test(text);
    case 'undershirt':
      return /undershirt|верхнее белье/.test(text);
    case 'tights':
      return /sock|tights|нос|колгот/.test(text);
    case 'chest':
      return /chest|badge|pin|груд/.test(text);
    default:
      return false;
  }
}

function getPreferenceIconCatalog(
  serverData: ServerData | undefined,
  preference: string,
): PreferenceIconCatalog | undefined {
  return serverData?.[preference] as PreferenceIconCatalog | undefined;
}

function PreferenceChoiceTile(props: {
  choice: string;
  current: string;
  icon?: string;
  label: string;
  onSelect: () => void;
}) {
  const { choice, current, icon, label, onSelect } = props;

  return (
    <div
      className={classes([
        'LoadoutStoreTile',
        choice === current && 'selected',
      ])}
      title={label}
      role="button"
      tabIndex={0}
      onClick={onSelect}
      onKeyDown={(event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          onSelect();
        }
      }}
    >
      <span className="LoadoutStoreTile__name">{label}</span>
      <span className="LoadoutStoreTile__icon">
        {icon ? (
          <ImageButton
            asset={['preferences32x32', icon]}
            imageSize={42}
            tooltip={label}
            tooltipPosition="right"
            onClick={onSelect}
          />
        ) : (
          <Icon name="shirt" />
        )}
      </span>
      <span className="LoadoutStoreTile__footer">
        <b>{choice === 'Nude' ? 0 : 1}</b>
        <em>{choice === current ? 'ON' : ''}</em>
      </span>
    </div>
  );
}

function itemMatchesCategory(item: CatalogItem, category: string) {
  return category === allCategory || item.category === category;
}

function itemMatchesSlot(item: CatalogItem, slot: string | null) {
  if (!slot) {
    return true;
  }
  const slotFlags = Number(item.slot_flags || 0);
  const desiredSlotFlags = slotFlagBySlot[slot] || groupedSlotFlags[slot] || 0;
  if (slotFlags && desiredSlotFlags) {
    return Boolean(slotFlags & desiredSlotFlags);
  }
  const text = `${item.category} ${item.group} ${item.name}`.toLowerCase();
  switch (slot) {
    case 'bag':
      return true;
    case 'hands':
    case 'hand_l':
    case 'hand_r':
      return /hand|рук|weapon|tool|gun|knife|sword/.test(text);
    case 'pockets':
    case 'pocket_l':
    case 'pocket_r':
      return /pocket|карман|small|box/.test(text);
    case 'belt':
      return /belt|пояс|tool|holster/.test(text);
    case 'neck':
      return /neck|tie|scarf|collar|cloak|шея|галстук|шарф|воротник|плащ/.test(text);
    case 'shoulders':
    case 'shoulder_l':
    case 'shoulder_r':
      return /bag|backpack|shoulder|плеч|сум|рюкзак/.test(text);
    case 'head':
      return /head|голов|hat|helmet|cap|beanie/.test(text);
    case 'body':
    case 'uniform':
    case 'suit':
    case 'pants':
      return /body|тело|uniform|suit|shirt|clothing|одеж|pants/.test(text);
    case 'mask':
      return /mask|маск/.test(text);
    case 'glasses':
      return /glasses|очки/.test(text);
    case 'gloves':
      return /glove|перчат/.test(text);
    case 'finger':
      return /ring|finger|кольц|палец/.test(text);
    case 'bracers':
      return /bracer|bracelet|нарукав|браслет/.test(text);
    case 'shoes':
      return /shoe|boot|сапог|ботин/.test(text);
    case 'ears':
      return /ear|уши|headset|headphone/.test(text);
    case 'chest':
      return /chest|груд|badge|pin|brooch/.test(text);
    default:
      return true;
  }
}

type StoreTileProps = {
  item: CatalogItem;
  selected?: boolean;
  disabled?: boolean;
  userTier: number;
  onSelect: () => void;
  onAdd: () => void;
};

function StoreTile(props: StoreTileProps) {
  const { disabled, item, onAdd, onSelect, selected, userTier } = props;
  const tier = item.tier || 0;

  return (
    <button
      className={classes([
        'LoadoutStoreTile',
        selected && 'selected',
        disabled && 'disabled',
      ])}
      disabled={disabled}
      title={
        disabled
          ? `${item.name} / ${item.category} / нужен T${tier}, у вас T${userTier}`
          : `${item.name} / ${item.category}`
      }
      onMouseEnter={onSelect}
      onFocus={onSelect}
      onClick={onAdd}
    >
      <span className="LoadoutStoreTile__name">{item.name}</span>
      <span className="LoadoutStoreTile__icon">
        {!!item.icon && !!item.icon_state ? (
          <DmIcon height="42px" width="42px" icon={item.icon} icon_state={item.icon_state} />
        ) : (
          <Icon name="cube" />
        )}
      </span>
      <span className="LoadoutStoreTile__footer">
        <b>{item.cost}</b>
        <em>T{tier}</em>
      </span>
    </button>
  );
}

export function EquipmentTab() {
  const { act, data } = useBackend<LoadoutManagerData>();
  const serverData = useServerPrefs();
  const [mode, setMode] = useState<EquipmentMode>('loadout');
  const [selectedPath, setSelectedPath] = useState<typePath | null>(null);
  const [modifyItemDimmer, setModifyItemDimmer] = useState<LoadoutItem | null>(
    null,
  );
  const [selectedCategory, setSelectedCategory] = useState(allCategory);
  const [selectedSlot, setSelectedSlot] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [equippedLoadoutSlots, setEquippedLoadoutSlots] = useState<Record<string, string>>({});
  const [equippedWardrobeSlots, setEquippedWardrobeSlots] = useState<Record<string, string>>({});
  const catalog = flattenLoadoutCatalog(serverData) || [];
  const catalogCategories = useMemo(
    () => [
      allCategory,
      ...(serverData?.loadout.loadout_tabs.map((category) => category.name) || []),
    ],
    [serverData],
  );
  const loadoutList = data.character_preferences.misc.loadout_list || {};
  const persistent = data.character_setup?.persistent;
  const wardrobeDesigns = persistent?.wardrobe || [];
  const availableWardrobeDesigns = wardrobeDesigns.filter(
    (design, index) =>
      !equippedWardrobeSlots[getWardrobeDesignId(design, index)],
  );
  const equippedWardrobeDesigns = wardrobeDesigns.filter((design, index) =>
    Boolean(equippedWardrobeSlots[getWardrobeDesignId(design, index)]),
  );
  const businessRecords = persistent?.business || [];
  const apartmentRecords = persistent?.apartments || [];

  const selectedSlots = Object.keys(loadoutList);
  const selectedItems = selectedSlots
    .map((path) => findLoadoutItem(catalog, path))
    .filter(Boolean) as CatalogItem[];

  const filteredCatalog = useMemo(() => {
    const query = search.toLowerCase();
    return catalog.filter((item) => {
      if (!itemMatchesCategory(item, selectedCategory)) {
        return false;
      }
      return (
        !query ||
        item.name.toLowerCase().includes(query) ||
        item.group.toLowerCase().includes(query)
      );
    });
  }, [catalog, search, selectedCategory]);

  const selectedSlotItems = selectedSlot
    ? selectedItems.filter((item) => itemMatchesSlot(item, selectedSlot))
    : [];
  const selectedSlotWardrobeDesigns = equippedWardrobeDesigns.filter((design) =>
    wardrobeDesigns.some((wardrobeDesign, index) => {
      const designId = getWardrobeDesignId(wardrobeDesign, index);
      return wardrobeDesign === design && equippedWardrobeSlots[designId] === selectedSlot;
    }),
  );
  const selectedUnderwearPreference = selectedSlot
    ? underwearPreferenceBySlot[selectedSlot]
    : undefined;
  const selectedUnderwearCatalog = selectedUnderwearPreference
    ? getPreferenceIconCatalog(serverData, selectedUnderwearPreference)
    : undefined;
  const preferenceData = data as unknown as Parameters<typeof getPreferenceValue>[0];
  const selectedUnderwearChoices =
    selectedUnderwearCatalog?.choices || Object.keys(selectedUnderwearCatalog?.icons || {});
  const selectedUnderwearValue = selectedUnderwearPreference
    ? String(getPreferenceValue(preferenceData, selectedUnderwearPreference) ?? '')
    : '';
  const spentPoints = Math.max(
    0,
    (data.loadout_maxpoints || 0) - (data.loadout_leftpoints || 0),
  );
  const spentRatio =
    data.loadout_maxpoints > 0
      ? Math.min(100, Math.max(0, (spentPoints / data.loadout_maxpoints) * 100))
      : 0;

  useEffect(() => {
    const nextSlots: Record<string, string> = {};
    Object.keys(loadoutList).forEach((path) => {
      const slot = getLoadoutEquipSlot(loadoutList, path);
      if (slot) {
        nextSlots[path] = slot;
      }
    });
    setEquippedLoadoutSlots(nextSlots);
  }, [loadoutList]);

  useEffect(() => {
    act('set_loadout_preview_override', {
      enabled: true,
      paths: Object.entries(equippedLoadoutSlots)
        .filter(([, slot]) => slot !== 'bag')
        .map(([path]) => path),
    });
  }, [act, equippedLoadoutSlots]);

  const renderSelectedLoadout = (
    compact = false,
    clickMode: 'remove' | 'inspect' = 'remove',
  ) =>
    selectedSlots.length ? (
      selectedSlots.map((path) => {
        const item = findLoadoutItem(catalog, path);
        return (
          <ItemCard
            key={path}
            selected={selectedPath === path}
            name={item?.name || path}
            icon={item?.icon}
            iconState={item?.icon_state}
            cost={compact ? undefined : item?.cost}
            amount={getLoadoutAmount(loadoutList, path)}
            meta={item?.group}
            tags={compact && item ? [item.category] : undefined}
            onClick={() => {
              setSelectedPath(path);
              if (clickMode === 'remove') {
                act('select_item', { path, deselect: true });
                return;
              }
            }}
            onContextMenu={
              clickMode === 'remove'
                ? () => {
                    setSelectedPath(null);
                    act('select_item', { path, deselect: true });
                  }
                : undefined
            }
            onAction={undefined}
          />
        );
      })
    ) : (
      <div className="CharacterSetup__empty">Снаряжение не выбрано.</div>
    );

  return (
    <div className="CharacterSetup__equipmentTab">
      {!!modifyItemDimmer && (
        <LoadoutModifyDimmer
          modifyItemDimmer={modifyItemDimmer}
          setModifyItemDimmer={setModifyItemDimmer}
        />
      )}
      <div className="CharacterSetup__segmented CharacterSetup__modeTabs">
        <button
          className={mode === 'loadout' ? 'active' : ''}
          onClick={() => setMode('loadout')}
        >
          Разгрузка
        </button>
        <button
          className={mode === 'equipment' ? 'active' : ''}
          onClick={() => setMode('equipment')}
        >
          Снаряжение
        </button>
      </div>

      {mode === 'loadout' ? (
        <div className="CharacterSetup__layout CharacterSetup__layout--loadout">
          <CyberPanel
            title="A. Выбранная разгрузка"
            subtitle={`Очки: ${data.loadout_leftpoints ?? 0}/${data.loadout_maxpoints ?? 0}`}
            scrollable
          >
            <div className="CharacterSetup__loadoutPoints">
              <span>
                {spentPoints}/{data.loadout_maxpoints || 0}
              </span>
              <i>
                <b style={{ width: `${spentRatio}%` }} />
              </i>
            </div>
            {renderSelectedLoadout()}

            <CyberButton danger icon="trash" onClick={() => act('clear_all_items')}>
              Очистить разгрузку
            </CyberButton>
          </CyberPanel>

          <CyberPanel
            className="CharacterSetup__loadoutStorePanel"
            title="B. Магазин разгрузки"
          >
            <div className="CharacterSetup__storeTools">
              <div className="CharacterSetup__loadoutSearch">
                <span className="CharacterSetup__loadoutSearchLabel">
                  Поиск
                </span>
                <input
                  className="CharacterSetup__loadoutSearchInput"
                  placeholder="Поиск предмета..."
                  value={search}
                  onChange={(event) => setSearch(event.currentTarget.value)}
                />
              </div>
              <div className="CharacterSetup__categoryTabs">
                {catalogCategories.map((category) => (
                  <button
                    key={category}
                    className={selectedCategory === category ? 'active' : ''}
                    onClick={() => setSelectedCategory(category)}
                  >
                    {category}
                  </button>
                ))}
              </div>
            </div>
            <div className="CharacterSetup__loadoutStoreGrid">
              {filteredCatalog.map((item) => (
                <StoreTile
                  key={item.path}
                  disabled={(item.tier || 0) > (data.donator_level || 0)}
                  item={item}
                  selected={!!loadoutList[item.path]}
                  userTier={data.donator_level || 0}
                  onSelect={() => setSelectedPath(item.path)}
                  onAdd={() => act('select_item', { path: item.path })}
                />
              ))}
            </div>
          </CyberPanel>
        </div>
      ) : (
        <div className="CharacterSetup__layout CharacterSetup__layout--equipment">
          <CyberPanel title="A. Что есть" scrollable>
            <CyberSectionHeader>Гардероб</CyberSectionHeader>
            {wardrobeDesigns.length ? (
              <div className="CharacterSetup__persistentList">
                {wardrobeDesigns.map((design: CyberpunkVisualDesign, index) => {
                  const designId = getWardrobeDesignId(design, index);
                  if (equippedWardrobeSlots[designId]) {
                    return null;
                  }
                  return (
                    <PersistentCard
                      key={designId}
                      icon="shirt"
                      title={design.name || 'Сохраненная вещь'}
                      subtitle={design.type_path || design.base || design.kind || 'wardrobe'}
                      meta={design.material_signature}
                      onClick={() => {
                        if (!selectedSlot || !wardrobeDesignMatchesSlot(design, selectedSlot)) {
                          return;
                        }
                        setEquippedWardrobeSlots((current) => ({
                          ...current,
                          [designId]: selectedSlot,
                        }));
                      }}
                    />
                  );
                })}
                {!availableWardrobeDesigns.length && (
                  <div className="CharacterSetup__empty">Все сохраненные вещи выбраны.</div>
                )}
              </div>
            ) : (
              <div className="CharacterSetup__empty">Сохраненных вещей нет.</div>
            )}

            {!!equippedWardrobeDesigns.length && (
              <>
                <CyberSectionHeader>Надето из гардероба</CyberSectionHeader>
                <div className="CharacterSetup__persistentList">
                  {wardrobeDesigns.map((design: CyberpunkVisualDesign, index) => {
                    const designId = getWardrobeDesignId(design, index);
                    const equippedSlot = equippedWardrobeSlots[designId];
                    if (!equippedSlot) {
                      return null;
                    }
                    return (
                      <PersistentCard
                        key={`equipped-${designId}`}
                        icon="shirt"
                        selected
                        title={design.name || 'Сохраненная вещь'}
                        subtitle={design.type_path || design.base || design.kind || 'wardrobe'}
                        meta={`${equippedSlot} / ПКМ снять`}
                        onClick={() => setSelectedSlot(null)}
                        onContextMenu={() =>
                          setEquippedWardrobeSlots((current) => {
                            const next = { ...current };
                            delete next[designId];
                            return next;
                          })
                        }
                      />
                    );
                  })}
                </div>
              </>
            )}

            <CyberSectionHeader>Бизнес</CyberSectionHeader>
            {businessRecords.length ? (
              <div className="CharacterSetup__persistentList">
                {businessRecords.map((record: CyberpunkPersistentAreaRecord, index) => (
                  <PersistentCard
                    key={record.id || `${record.name}-${index}`}
                    icon="briefcase"
                    title={record.name || 'Бизнес'}
                    subtitle={formatAreaRecord(record)}
                    meta={record.legal ? 'legal' : 'grey'}
                  />
                ))}
              </div>
            ) : (
              <div className="CharacterSetup__empty">Сохраненного бизнеса нет.</div>
            )}

            <CyberSectionHeader>Квартира</CyberSectionHeader>
            {apartmentRecords.length ? (
              <div className="CharacterSetup__persistentList">
                {apartmentRecords.map((record: CyberpunkPersistentAreaRecord, index) => (
                  <PersistentCard
                    key={record.id || `${record.name}-${index}`}
                    icon="house"
                    title={record.name || 'Квартира'}
                    subtitle={formatAreaRecord(record)}
                    meta={record.saved_at}
                  />
                ))}
              </div>
            ) : (
              <div className="CharacterSetup__empty">Сохраненной квартиры нет.</div>
            )}

            <CyberSectionHeader>Разгрузка</CyberSectionHeader>
            {renderSelectedLoadout(true, 'inspect')}
          </CyberPanel>

          <CyberPanel
            className="CharacterSetup__centerPanel CharacterSetup__equipmentDollPanel"
            title="B. Где лежит и как выглядит"
          >
            <div className="CharacterSetup__equipmentFixed">
              <div className="CharacterSetup__equipmentPreview">
                <CharacterPreview
                  height="250px"
                  id={data.character_preview_view}
                  transparent
                />
              </div>
              <div className="CharacterSetup__equipmentSlotGridWrap">
                <LoadoutSlotGrid
                  selectedSlot={selectedSlot || undefined}
                  onSelect={(slot) => setSelectedSlot(selectedSlot === slot ? null : slot)}
                />
              </div>
            </div>

            <CyberSectionHeader>
              {selectedSlot ? 'Предметы выбранного слота' : 'Выберите слот'}
            </CyberSectionHeader>
            <div className="CharacterSetup__equipmentSlotItems">
              {selectedUnderwearPreference ? (
                <>
                  <div className="CharacterSetup__equipmentSlotHeader">
                    <b>{underwearSlotLabels[selectedSlot || ''] || selectedSlot}</b>
                    <span>
                      {getDisplayName(
                        serverData,
                        selectedUnderwearPreference,
                        selectedUnderwearValue,
                      )}
                    </span>
                  </div>
                  {selectedUnderwearPreference === 'underwear' && (
                    <CyberColorButton
                      buttonLabel="Выбрать цвет"
                      color={String(getPreferenceValue(preferenceData, 'underwear_color') ?? '')}
                      icon="palette"
                      label="Цвет нижнего белья"
                      onClick={() =>
                        act('set_color_preference', {
                          preference: 'underwear_color',
                        })
                      }
                    />
                  )}
                  <div className="CharacterSetup__loadoutStoreGrid CharacterSetup__underwearCatalog">
                    {selectedUnderwearChoices.map((choice) => (
                      <PreferenceChoiceTile
                        key={choice}
                        choice={choice}
                        current={selectedUnderwearValue}
                        icon={selectedUnderwearCatalog?.icons?.[choice]}
                        label={
                          selectedUnderwearCatalog?.display_names?.[choice] ||
                          getDisplayName(serverData, selectedUnderwearPreference, choice)
                        }
                        onSelect={() =>
                          setPreference(act, selectedUnderwearPreference, choice)
                        }
                      />
                    ))}
                  </div>
                </>
              ) : selectedSlotItems.length || selectedSlotWardrobeDesigns.length ? (
                <>
                  {selectedSlotWardrobeDesigns.map((design) => {
                    const designId = Object.keys(equippedWardrobeSlots).find((id) =>
                      wardrobeDesigns.some(
                        (wardrobeDesign, index) =>
                          getWardrobeDesignId(wardrobeDesign, index) === id &&
                          wardrobeDesign === design,
                      ),
                    );
                    return (
                      <ItemCard
                        key={`wardrobe-${designId || design.name}`}
                        name={design.name || 'Сохраненная вещь'}
                        meta={design.type_path || design.base || design.kind || 'wardrobe'}
                        tags={['Гардероб']}
                        selected
                        onClick={undefined}
                        onContextMenu={() => {
                          if (!designId) {
                            return;
                          }
                          setEquippedWardrobeSlots((current) => {
                            const next = { ...current };
                            delete next[designId];
                            return next;
                          });
                        }}
                        onAction={undefined}
                      />
                    );
                  })}
                  {selectedSlotItems.map((item) => (
                    <ItemCard
                      key={item.path}
                      name={item.name}
                      icon={item.icon}
                      iconState={item.icon_state}
                      cost={item.cost}
                      amount={getLoadoutAmount(loadoutList, item.path)}
                      meta={item.group}
                      tags={[item.category]}
                      selected={equippedLoadoutSlots[item.path] === selectedSlot}
                      onClick={() => {
                        if (!selectedSlot) {
                          return;
                        }
                        setSelectedPath(item.path);
                        act('set_loadout_slot', {
                          path: item.path,
                          slot: selectedSlot,
                        });
                        setEquippedLoadoutSlots((current) => ({
                          ...current,
                          [item.path]: selectedSlot,
                        }));
                      }}
                      onContextMenu={() => {
                        setSelectedPath(null);
                        act('set_loadout_slot', {
                          path: item.path,
                          slot: null,
                        });
                        setEquippedLoadoutSlots((current) => {
                          const next = { ...current };
                          delete next[item.path];
                          return next;
                        });
                      }}
                      onAction={undefined}
                    />
                  ))}
                </>
              ) : (
                <div className="CharacterSetup__empty">
                  Выберите слот, чтобы отфильтровать набранные вещи.
                </div>
              )}
            </div>
          </CyberPanel>
        </div>
      )}
    </div>
  );
}
