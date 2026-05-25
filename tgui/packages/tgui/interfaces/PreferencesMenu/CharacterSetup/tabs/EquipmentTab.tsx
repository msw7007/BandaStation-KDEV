import { useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';

import type {
  LoadoutItem,
  LoadoutManagerData,
  typePath,
} from '../../CharacterPreferences/loadout/base';
import { useServerPrefs } from '../../useServerPrefs';
import { CharacterPaperdollHub } from '../components/CharacterPaperdollHub';
import { CyberButton, CyberSearch } from '../components/CyberInput';
import { CyberPanel, CyberSectionHeader } from '../components/CyberPanel';
import { ItemCard } from '../components/ItemCard';
import { LoadoutSlotGrid } from '../components/LoadoutSlotGrid';
import { flattenLoadoutCatalog } from '../helpers';

const catalogCategories = [
  'Всё',
  'Оружие',
  'Броня',
  'Инструменты',
  'Медицина',
  'Одежда',
  'Контейнеры',
  'Другое',
];

function findLoadoutItem(items: Array<LoadoutItem & { category: string }>, path: typePath) {
  return items.find((item) => item.path === path);
}

function itemMatchesCategory(item: LoadoutItem & { category: string }, category: string) {
  if (category === 'Всё') {
    return true;
  }
  const text = `${item.category} ${item.group} ${item.name}`.toLowerCase();
  switch (category) {
    case 'Оружие':
      return /weapon|оруж|gun|knife|sword/.test(text);
    case 'Броня':
      return /armor|брон|helmet|suit/.test(text);
    case 'Инструменты':
      return /tool|инструмент/.test(text);
    case 'Медицина':
      return /medical|med|мед/.test(text);
    case 'Одежда':
      return /clothing|одеж|uniform|shirt|shoes/.test(text);
    case 'Контейнеры':
      return /bag|backpack|box|container|сум|рюкзак/.test(text);
    default:
      return true;
  }
}

export function EquipmentTab() {
  const { act, data } = useBackend<LoadoutManagerData>();
  const serverData = useServerPrefs();
  const [selectedPath, setSelectedPath] = useState<typePath | null>(null);
  const [selectedCategory, setSelectedCategory] = useState('Всё');
  const [search, setSearch] = useState('');
  const catalog = flattenLoadoutCatalog(serverData) || [];
  const loadoutList = data.character_preferences.misc.loadout_list || {};

  const selectedItem = selectedPath
    ? findLoadoutItem(catalog, selectedPath)
    : undefined;

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

  const selectedSlots = Object.keys(loadoutList);

  return (
    <div className="CharacterSetup__layout">
      <CyberPanel
        title="A. Выбранное снаряжение"
        subtitle={`Очки: ${data.loadout_leftpoints ?? 0}/${data.loadout_maxpoints ?? 0}`}
        scrollable
      >
        {selectedSlots.length ? (
          selectedSlots.map((path) => {
            const item = findLoadoutItem(catalog, path);
            return (
              <ItemCard
                key={path}
                selected={selectedPath === path}
                name={item?.name || path}
                icon={item?.icon}
                iconState={item?.icon_state}
                cost={item?.cost}
                meta={item?.group}
                actionIcon="times"
                onClick={() => setSelectedPath(path)}
                onAction={() => act('select_item', { path, deselect: true })}
              />
            );
          })
        ) : (
          <div className="CharacterSetup__empty">Снаряжение не выбрано.</div>
        )}

        <CyberSectionHeader>Настройка выбранного предмета</CyberSectionHeader>
        {selectedItem ? (
          <div className="CharacterSetup__details">
            <h3>{selectedItem.name}</h3>
            <p>{selectedItem.group}</p>
            <span>Стоимость: {selectedItem.cost}</span>
            <span>Размер/качество/модули: TODO, backend не отдает эти поля.</span>
            <CyberButton disabled icon="plus">
              Количество +/-
            </CyberButton>
            <CyberButton disabled icon="puzzle-piece">
              Доп. модули
            </CyberButton>
          </div>
        ) : (
          <div className="CharacterSetup__empty">Выберите предмет.</div>
        )}

        <CyberSectionHeader>Постоянные технологии</CyberSectionHeader>
        <div className="CharacterSetup__placeholderGrid">
          {[1, 2, 3, 4, 5, 6].map((slot) => (
            <CyberButton key={slot} disabled icon="microchip">
              Слот {slot}
            </CyberButton>
          ))}
        </div>
        <CyberButton danger icon="trash" onClick={() => act('clear_all_items')}>
          Очистить покупки
        </CyberButton>
      </CyberPanel>

      <CyberPanel className="CharacterSetup__centerPanel" title="Слоты снаряжения">
        <CharacterPaperdollHub
          previewId={data.character_preview_view}
          slots={[
            { id: 'hands', label: 'Две руки', icon: 'hand' },
            { id: 'pockets', label: 'Два кармана', icon: 'box' },
            { id: 'belt', label: 'Пояс', icon: 'circle-notch' },
            { id: 'shoulders', label: 'Плечи', icon: 'briefcase' },
            { id: 'head', label: 'Голова', icon: 'helmet-safety' },
            { id: 'body', label: 'Тело', icon: 'shirt' },
          ].map((slot) => ({
            ...slot,
            disabled: true,
            state: 'TODO',
            warning: 'TODO: assigning loadout items to exact slots needs backend support.',
          }))}
        />
        <LoadoutSlotGrid disabled />
        <div className="CharacterSetup__quickSlots">
          {[1, 2, 3, 4, 5, 6].map((slot) => (
            <button key={slot} disabled>
              {slot}
            </button>
          ))}
        </div>
      </CyberPanel>

      <CyberPanel title="B. Магазин снаряжения" scrollable>
        <CyberSearch
          placeholder="Поиск предмета..."
          value={search}
          onChange={setSearch}
        />
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
        <div className="CharacterSetup__catalog">
          {filteredCatalog.map((item) => (
            <ItemCard
              key={item.path}
              name={item.name}
              icon={item.icon}
              iconState={item.icon_state}
              cost={item.cost}
              meta={item.group}
              tags={[item.category]}
              selected={!!loadoutList[item.path]}
              onClick={() => setSelectedPath(item.path)}
              onAction={() => act('select_item', { path: item.path })}
            />
          ))}
        </div>
        <CyberButton disabled icon="check">
          Подтвердить снаряжение
        </CyberButton>
      </CyberPanel>
    </div>
  );
}
