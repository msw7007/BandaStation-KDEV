import type { Job, RoleOutfitItem } from '../../types';
import { CyberSectionHeader } from './CyberPanel';
import { ItemCard } from './ItemCard';

type RoleGearPreviewProps = {
  roleId?: string;
  job?: Job;
};

function groupOutfitItems(items: RoleOutfitItem[]) {
  const grouped: Record<string, RoleOutfitItem[]> = {};
  for (const item of items) {
    grouped[item.slot] ||= [];
    grouped[item.slot].push(item);
  }
  return grouped;
}

export function RoleGearPreview(props: RoleGearPreviewProps) {
  const { job, roleId } = props;
  const outfitItems = job?.outfit_items || [];
  const groupedItems = groupOutfitItems(outfitItems);

  if (!roleId || !job) {
    return (
      <div className="RoleGearPreview empty">
        Выберите роль для просмотра стартового набора.
      </div>
    );
  }

  return (
    <div className="RoleGearPreview">
      <CyberSectionHeader>{roleId}</CyberSectionHeader>
      <p>{job.description}</p>
      <div className="RoleGearPreview__meta">
        <span>Отдел: {job.department}</span>
        {!!job.supervisors && <span>Руководство: {job.supervisors}</span>}
        {job.paycheck !== undefined && <span>Кредиты: {job.paycheck}</span>}
        {job.spawn_positions !== undefined && (
          <span>Слоты: {job.spawn_positions}/{job.total_positions}</span>
        )}
      </div>
      <div className="RoleGearPreview__notice">
        Это предварительный просмотр. Игра попытается выдать эти предметы при
        старте роли; итог зависит от доступности, слотов, species/body
        restrictions и backend outfit logic.
      </div>
      <div className="RoleGearPreview__grid">
        {Object.entries(groupedItems).map(([slot, items]) => (
          <div key={slot} className="RoleGearPreview__slot">
            <b>{slot}</b>
            {items.map((item, index) => (
              <ItemCard
                key={`${slot}-${item.item_type}-${index}`}
                name={item.item_name}
                icon={item.icon}
                iconState={item.icon_state}
                meta={item.guaranteed ? item.source : `${item.source} / попытка`}
                tags={item.warning ? [item.warning] : undefined}
              />
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}

