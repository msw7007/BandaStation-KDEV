import { useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { DmIcon, Icon } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import type {
  LoadoutItem,
  LoadoutManagerData,
  typePath,
} from '../../CharacterPreferences/loadout/base';
import { useServerPrefs } from '../../useServerPrefs';
import { CharacterPaperdollHub } from '../components/CharacterPaperdollHub';
import { CyberButton } from '../components/CyberInput';
import { CyberPanel, CyberSectionHeader } from '../components/CyberPanel';
import { ItemCard } from '../components/ItemCard';
import { LoadoutSlotGrid } from '../components/LoadoutSlotGrid';
import { flattenLoadoutCatalog } from '../helpers';

const allCategory = 'Все';

const hubSlots = [
  { id: 'hands', label: 'Две руки', icon: 'hand' },
  { id: 'pockets', label: 'Два кармана', icon: 'box' },
  { id: 'belt', label: 'Пояс', icon: 'circle-notch' },
  { id: 'shoulders', label: 'Плечи', icon: 'briefcase' },
  { id: 'head', label: 'Голова', icon: 'helmet-safety' },
  { id: 'body', label: 'Тело', icon: 'shirt' },
];

type EquipmentMode = 'loadout' | 'equipment';

type CatalogItem = LoadoutItem & { category: string };

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

function itemMatchesCategory(item: CatalogItem, category: string) {
  return category === allCategory || item.category === category;
}

function itemMatchesSlot(item: CatalogItem, slot: string | null) {
  if (!slot) {
    return true;
  }
  const text = `${item.category} ${item.group} ${item.name}`.toLowerCase();
  switch (slot) {
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
    case 'shoes':
      return /shoe|boot|сапог|ботин/.test(text);
    case 'ears':
      return /ear|уши|headset|headphone/.test(text);
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
  const [selectedCategory, setSelectedCategory] = useState(allCategory);
  const [selectedSlot, setSelectedSlot] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const catalog = flattenLoadoutCatalog(serverData) || [];
  const catalogCategories = useMemo(
    () => [
      allCategory,
      ...(serverData?.loadout.loadout_tabs.map((category) => category.name) || []),
    ],
    [serverData],
  );
  const loadoutList = data.character_preferences.misc.loadout_list || {};

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
    : selectedItems;
  const spentPoints = Math.max(
    0,
    (data.loadout_maxpoints || 0) - (data.loadout_leftpoints || 0),
  );
  const spentRatio =
    data.loadout_maxpoints > 0
      ? Math.min(100, Math.max(0, (spentPoints / data.loadout_maxpoints) * 100))
      : 0;

  const renderSelectedLoadout = (compact = false) =>
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
            onClick={() => act('select_item', { path, deselect: true })}
            onAction={undefined}
          />
        );
      })
    ) : (
      <div className="CharacterSetup__empty">Снаряжение не выбрано.</div>
    );

  return (
    <div className="CharacterSetup__equipmentTab">
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
            <CyberSectionHeader>Разгрузка</CyberSectionHeader>
            {renderSelectedLoadout(true)}

            <CyberSectionHeader>Персистент</CyberSectionHeader>
            <div className="CharacterSetup__localNote">
              Бизнес, квартира, гардеробные вещи и дизайнерские копии хранятся
              персистентно, но извлекаются игровыми терминалами и гардеробом.
              Здесь они показываются как источник снаряжения, не как магазин.
            </div>
          </CyberPanel>

          <CyberPanel
            className="CharacterSetup__centerPanel CharacterSetup__equipmentDollPanel"
            title="B. Где лежит и как выглядит"
            scrollable
          >
            <CharacterPaperdollHub
              previewId={data.character_preview_view}
              selectedSlot={selectedSlot || undefined}
              slots={hubSlots.map((slot) => ({
                ...slot,
                state: selectedSlot === slot.id ? 'выбрано' : undefined,
              }))}
              onSelectSlot={(slot) => setSelectedSlot(selectedSlot === slot ? null : slot)}
            />

            <CyberSectionHeader>Слоты</CyberSectionHeader>
            <LoadoutSlotGrid
              selectedSlot={selectedSlot || undefined}
              onSelect={(slot) => setSelectedSlot(selectedSlot === slot ? null : slot)}
            />

            <CyberSectionHeader>
              {selectedSlot ? 'Предметы выбранного слота' : 'Все набранные вещи'}
            </CyberSectionHeader>
            <div className="CharacterSetup__equipmentSlotItems">
              {selectedSlotItems.length ? (
                selectedSlotItems.map((item) => (
                  <ItemCard
                    key={item.path}
                    name={item.name}
                    icon={item.icon}
                    iconState={item.icon_state}
                    cost={item.cost}
                    amount={getLoadoutAmount(loadoutList, item.path)}
                    meta={item.group}
                    tags={[item.category]}
                    selected={selectedPath === item.path}
                    onClick={() => act('select_item', { path: item.path, deselect: true })}
                    onAction={undefined}
                  />
                ))
              ) : (
                <div className="CharacterSetup__empty">
                  Для этого слота пока нет выбранных вещей.
                </div>
              )}
            </div>
          </CyberPanel>
        </div>
      )}
    </div>
  );
}
